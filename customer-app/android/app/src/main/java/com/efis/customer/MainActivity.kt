package com.efis.customer
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

class MainActivity:ComponentActivity(){override fun onCreate(b:Bundle?){super.onCreate(b);setContent{MaterialTheme{App()}}}}
@Composable fun App(){
 var cached by remember{mutableStateOf(false)}; var connected by remember{mutableStateOf(false)}
 Scaffold(topBar={TopAppBar(title={Text("MicroSky Horizon")})}){p->
  Column(Modifier.padding(p).padding(18.dp),verticalArrangement=Arrangement.spacedBy(12.dp)){
   Text("EFIS-DEMO-0001",style=MaterialTheme.typography.headlineSmall)
   Text("Firmware release set",style=MaterialTheme.typography.titleLarge)
   Card{Column(Modifier.padding(16.dp),verticalArrangement=Arrangement.spacedBy(5.dp)){
    Text("EIU  1.7.0 → 1.9.0"); Text("AEF-CAN 1.3 • ENGINE_DATA_V1+V2 • OTA_V1",style=MaterialTheme.typography.bodySmall)
    Text("Horizon  2.4.0 → 2.5.0"); Text("AEF-CAN 1.3 • ENGINE_DATA_V2 • OTA_V1",style=MaterialTheme.typography.bodySmall)
    Text("Safe update order: EIU → Horizon")
   }}
   Button({cached=true},enabled=!cached){Text(if(cached)"Release Set Cached" else "Cache Release Set for Offline Update")}
   Row{Checkbox(connected,{connected=it});Text("Connected to Horizon maintenance Wi-Fi",Modifier.padding(top=12.dp))}
   Button({},enabled=cached&&connected){Text("Transfer Cached Release Set to Horizon")}
   Text("Horizon verifies signatures, hardware, capabilities and safe sequencing. EIU firmware is delivered by Horizon over AEF-CAN.",style=MaterialTheme.typography.bodySmall)
  }
 }
}
