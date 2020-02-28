switch ($args[0]) {
    { $_ -in 'dev', 'build' } {
        jane $args
        return
    }

    'deploy' {
        $buildDir = '..\build'
        $hostName = 'aliyun'
        $tmpZip = 'C:\Zone\public\_jane.tmp.zip'
        $tmpDir = 'C:\Zone\public\_jane.tmp'
        $webDir = 'C:\Zone\public\jane.pandolia.net'

        zip $buildDir _tmp.zip
        scp _tmp.zip "$hostName`:$tmpZip"; check-code; Remove-Item _tmp.zip
        
        $sshCommand = "powershell -Command `"unzip $tmpZip $tmpDir`" & del /Q $tmpZip & "
        $sshCommand += "robocopy /mir $tmpDir $webDir & rmdir /S /Q $tmpDir"
        ssh $hostName cmd /c $sshCommand 2>&1 1>_out.txt; Get-Content _out.txt; Remove-Item _out.txt

        return
    }

    default {
        Write-Host ("Bad command " + $args[0])
    }
}