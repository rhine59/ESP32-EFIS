package com.efis.customer
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
class MainActivity:ComponentActivity(){override fun onCreate(b:Bundle?){super.onCreate(b);setContent{MaterialTheme{App()}}}}
@Composable fun App(){Scaffold(topBar={TopAppBar(title={Text("EFIS Account")})}){p->Column(Modifier.padding(p).padding(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)){Text("My instruments",style=MaterialTheme.typography.headlineMedium);Card{Column(Modifier.padding(18.dp)){Text("EFIS-DEMO-0001");Text("Demo / not activated");Button({},enabled=false){Text("Get / Refresh Licence")};TextButton({},enabled=false){Text("Manage Payment")}}};OutlinedButton({}){Text("Register an EFIS")};Text("Secure account API/payment/licence integration pending.",style=MaterialTheme.typography.bodySmall)}}}
