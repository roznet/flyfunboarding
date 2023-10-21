#!/bin/zsh
#
#
curl -v -X POST -F 'systemName=ios' -F 'applicationName=FLightLogStats' -F 'systemVersion=16.0' -F 'version=1.0' -F 'build=1' -F 'commonid=-1' -F 'platformString=ios12' -F 'file=@samples/bugreport.zip' 'https://localhost.ro-z.me/flyfunboarding/bugreport/new.php?debug=1'
