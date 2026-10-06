package com.lollipop.efis

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.google.zxing.integration.android.IntentIntegrator
import com.journeyapps.barcodescanner.ScanContract
import com.journeyapps.barcodescanner.ScanOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.net.URLEncoder
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.time.Instant
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

private const val ACCOUNT_BASE="https://granvillehouse.synology.me:8450"
data class AccountSession(val userId:Int,val email:String,val token:String,val expiresAt:String)
data class ProcessDef(val id:String,val title:String,val subtitle:String,val steps:List<String>)
private val processes=listOf(
 ProcessDef("setup","Set up a new EFIS","Register, licence, install and verify a new unit",listOf("Identify EFIS","Register owner","Choose licence","Obtain signed licence","Install on EFIS","Verify installation")),
 ProcessDef("buy","Buy / activate a licence","Use the included first year or buy the next licence term",listOf("Identify RedOne","Check included first year","Confirm owner","Activate or buy licence","Obtain signed licence","Install on EFIS","Verify VALID","Show renewal date")),
 ProcessDef("reassign","Reassign / sell an EFIS","Transfer ownership safely to another user",listOf("Confirm current EFIS","Identify new owner","Wait for buyer acceptance","Issue replacement licence","Install on EFIS","Verify new ownership")),
 ProcessDef("receive","Receive a transferred EFIS","Accept ownership and install your licence",listOf("Open transfer invitation","Authenticate buyer","Accept ownership","Obtain replacement licence","Install on EFIS","Verify ownership")),
 ProcessDef("renew","Renew / manage a licence","Review entitlement and renewal state",listOf("Identify licence","Review status","Choose renewal action","Confirm change","Verify entitlement")),
 ProcessDef("install","Install / update a licence","Securely install a signed entitlement",listOf("Connect to EFIS","Obtain signed entitlement","Transfer to EFIS","Verify signature and device","Persist licence","Confirm VALID")),
 ProcessDef("replace","Replace an EFIS","Move service to replacement hardware",listOf("Identify old EFIS","Identify replacement","Check eligibility","Migrate entitlement","Install licence","Retire old association")),
 ProcessDef("recover","Recover licence access","Recover after phone replacement or lost cache",listOf("Authenticate","Find owned EFIS","Retrieve entitlement","Reconnect to EFIS","Install licence","Verify")),
 ProcessDef("firmware","Update EFIS firmware","Guided OTA with compatibility and recovery checks",listOf("Identify EFIS","Check versions","Check compatibility","Acquire firmware","Transfer and validate","Activate and reboot","Post-update checks")),
 ProcessDef("commission","Commission an EFIS","Bring a complete EFIS / SMUX installation into service",listOf("Connect","Identify hardware","Check firmware","Check licence","Discover SMUX / CAN","Configure sensors","Set units and thresholds","Validate displays","Complete commissioning")),
 ProcessDef("diagnose","Diagnose a problem","Collect state, guide checks and verify the repair",listOf("Connect","Collect system state","Identify affected subsystem","Run guided checks","Apply corrective action","Retest","Record result")))

class SecureSession(private val c:Context){
 private val prefs=c.getSharedPreferences("lollipop-secure",Context.MODE_PRIVATE); private val alias="lollipop-account-session"
 private fun key():SecretKey{val ks=KeyStore.getInstance("AndroidKeyStore").apply{load(null)}; (ks.getKey(alias,null) as? SecretKey)?.let{return it}; val kg=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");kg.init(KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT).setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());return kg.generateKey()}
 fun save(s:AccountSession){val j=JSONObject().put("userId",s.userId).put("email",s.email).put("token",s.token).put("expiresAt",s.expiresAt).toString().toByteArray();val cipher=Cipher.getInstance("AES/GCM/NoPadding");cipher.init(Cipher.ENCRYPT_MODE,key());prefs.edit().putString("iv",Base64.encodeToString(cipher.iv,Base64.NO_WRAP)).putString("data",Base64.encodeToString(cipher.doFinal(j),Base64.NO_WRAP)).apply()}
 fun load():AccountSession?=try{val iv=Base64.decode(prefs.getString("iv",null),Base64.NO_WRAP);val data=Base64.decode(prefs.getString("data",null),Base64.NO_WRAP);val cipher=Cipher.getInstance("AES/GCM/NoPadding");cipher.init(Cipher.DECRYPT_MODE,key(),GCMParameterSpec(128,iv));val j=JSONObject(String(cipher.doFinal(data)));AccountSession(j.getInt("userId"),j.getString("email"),j.getString("token"),j.getString("expiresAt"))}catch(_:Exception){null}
 fun clear(){prefs.edit().clear().apply()}
}

object Api{
 private fun call(path:String,method:String="GET",body:String?=null,token:String?=null):Pair<Int,String>{val c=URL(ACCOUNT_BASE+path).openConnection() as HttpURLConnection;c.requestMethod=method;c.connectTimeout=10000;c.readTimeout=10000;if(token!=null)c.setRequestProperty("Authorization","Bearer $token");if(body!=null){c.doOutput=true;c.setRequestProperty("Content-Type","application/x-www-form-urlencoded");c.outputStream.use{it.write(body.toByteArray())}};val code=c.responseCode;val stream=if(code in 200..299)c.inputStream else c.errorStream;return code to (stream?.bufferedReader()?.readText().orEmpty())}
 fun exchange(code:String):AccountSession{val (status,text)=call("/v1/app-login/exchange","POST","code="+URLEncoder.encode(code,"UTF-8"));if(status!=200)error("Sign-in code rejected or expired");val j=JSONObject(text);return AccountSession(j.getInt("user_id"),j.getString("email"),j.getString("session_token"),j.getString("expires_at"))}
 fun me(s:AccountSession):Boolean=call("/v1/me",token=s.token).first==200
 fun logout(s:AccountSession){call("/v1/logout","POST",token=s.token)}
 fun email(s:AccountSession){call("/v1/app-login/email","POST","email="+URLEncoder.encode(s.email,"UTF-8"))}
}

class MainActivity:ComponentActivity(){
 private lateinit var secure:SecureSession
 override fun onCreate(b:Bundle?){super.onCreate(b);secure=SecureSession(this);setContent{MaterialTheme{LollipopApp(secure,intent)}}}
 override fun onNewIntent(i:Intent){super.onNewIntent(i);intent=i}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable fun LollipopApp(secure:SecureSession,initialIntent:Intent){
 val scope=rememberCoroutineScope();var session by remember{mutableStateOf(secure.load())};var status by remember{mutableStateOf("Ready")};var selected by remember{mutableStateOf<ProcessDef?>(null)}
 suspend fun consume(raw:String){try{val u=URI(raw);if(u.scheme!="efisservice"||u.host!="login")error("Not a Lollipop sign-in QR");val code=u.rawQuery?.split("&")?.firstOrNull{it.startsWith("code=")}?.substringAfter("code=")?:error("Missing sign-in code");val s=withContext(Dispatchers.IO){Api.exchange(java.net.URLDecoder.decode(code,"UTF-8"))};secure.save(s);session=s;status="Signed in as ${s.email}"}catch(e:Exception){status=e.message?:"Sign-in failed"}}
 val scanner=rememberLauncherForActivityResult(ScanContract()){r->r.contents?.let{scope.launch{consume(it)}}}
 LaunchedEffect(Unit){initialIntent.dataString?.let{consume(it)};session?.let{s->if(runCatching{Instant.parse(s.expiresAt).isBefore(Instant.now())}.getOrDefault(true)){withContext(Dispatchers.IO){runCatching{Api.email(s)}};secure.clear();session=null;status="Sign-in expired — check your email for a new QR code."}else{val ok=withContext(Dispatchers.IO){runCatching{Api.me(s)}.getOrDefault(true)};if(!ok){withContext(Dispatchers.IO){runCatching{Api.email(s)}};secure.clear();session=null;status="Session expired — a new sign-in email has been sent."}}}}
 Scaffold(topBar={TopAppBar(title={Text("Lollipop")})}){pad->if(selected!=null){ProcessScreen(selected!!,{selected=null},Modifier.padding(pad))}else LazyColumn(Modifier.padding(pad).padding(16.dp),verticalArrangement=Arrangement.spacedBy(10.dp)){
  item{Text("What do you want to do?",style=MaterialTheme.typography.headlineSmall);Text("Choose a process. Lollipop mirrors the RedOne workflow on iPhone.",color=MaterialTheme.colorScheme.onSurfaceVariant)}
  item{Card{Column(Modifier.padding(14.dp),verticalArrangement=Arrangement.spacedBy(8.dp)){Text("Lollipop account",style=MaterialTheme.typography.titleMedium);if(session!=null){Text("Signed in as ${session!!.email}");TextButton(onClick={scope.launch{withContext(Dispatchers.IO){runCatching{Api.logout(session!!)}};secure.clear();session=null;status="Signed out"}}){Text("Sign out")}}else Button(onClick={scanner.launch(ScanOptions().setPrompt("Scan Lollipop sign-in QR").setBeepEnabled(false))}){Icon(Icons.Default.QrCodeScanner,null);Spacer(Modifier.width(8.dp));Text("Scan sign-in QR code")};Text(status,style=MaterialTheme.typography.bodySmall)}}}
  items(processes){p->Card(onClick={selected=p}){Column(Modifier.fillMaxWidth().padding(14.dp)){Text(p.title,style=MaterialTheme.typography.titleMedium);Text(p.subtitle,style=MaterialTheme.typography.bodySmall,color=MaterialTheme.colorScheme.onSurfaceVariant)}}}
 }}
}
@Composable fun ProcessScreen(p:ProcessDef,back:()->Unit,modifier:Modifier=Modifier){Column(modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(10.dp)){TextButton(onClick=back){Icon(Icons.Default.ArrowBack,null);Text("Processes")};Text(p.title,style=MaterialTheme.typography.headlineSmall);Text(p.subtitle);p.steps.forEachIndexed{i,s->ListItem(headlineContent={Text(s)},leadingContent={Text("${i+1}")})}}}
