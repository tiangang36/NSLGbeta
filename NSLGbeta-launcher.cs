using System;
using System.IO;
using System.Diagnostics;
using System.Windows.Forms;
using System.Threading;
class NSLGbeta {
 static string Root = AppDomain.CurrentDomain.BaseDirectory;
 static string Validate() {
  string[] files={"Start-Offline.ps1","offline-runtime.js","cached-bootstrap.ljbc","original-patcher.ljbc","local-account.ljbc","recruit-runtime.ljbc","recruit-engine.ljbc"};
  foreach(string f in files) if(!File.Exists(Path.Combine(Root,f))) return "Missing file: "+f;
  string[] dependencies={@"D:\bilibili Game\NSL_2\NSLG Game\com.bilibili.nslg.exe",@"C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe",@"C:\Users\Administrator\.codex\tools\rea\node_modules\rea-agents\scripts\rea.mjs"};
  foreach(string f in dependencies) if(!File.Exists(f))return "Missing dependency: "+f;
  return null;
 }
 [STAThread] static int Main(string[] args) {
  string error=Validate();
  if(args.Length>0 && args[0]=="--self-test") { File.WriteAllText(Path.Combine(Root,"launcher-self-test.txt"),error??"PASS: launch files and local dependencies exist");return error==null?0:1; }
  if(error!=null){MessageBox.Show(error,"NSLGbeta",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
  bool fresh;using(Mutex mutex=new Mutex(true,"Local\\NSLGbetaLauncher",out fresh)){
   if(!fresh){MessageBox.Show("NSLGbeta launcher is already running.","NSLGbeta");return 0;}
   try {
    if(Process.GetProcessesByName("com.bilibili.nslg").Length>0){MessageBox.Show("Please exit the running game first, then start NSLGbeta.","NSLGbeta");return 0;}
    ProcessStartInfo psi=new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"WindowsPowerShell\v1.0\powershell.exe"));
    psi.Arguments="-NoProfile -ExecutionPolicy Bypass -File \""+Path.Combine(Root,"Start-Offline.ps1")+"\"";
    psi.UseShellExecute=true;psi.Verb="runas";psi.WindowStyle=ProcessWindowStyle.Hidden;psi.WorkingDirectory=Root;
    using(Process p=Process.Start(psi)){p.WaitForExit();if(p.ExitCode!=0)MessageBox.Show("Startup failed. See launcher-error.txt in this folder.","NSLGbeta",MessageBoxButtons.OK,MessageBoxIcon.Error);return p.ExitCode;}
   }catch(Exception ex){MessageBox.Show(ex.Message,"NSLGbeta",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
  }
 }
}
