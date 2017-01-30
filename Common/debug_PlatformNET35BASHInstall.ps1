tar -zxvf sxs.tar.gz -C /cygdrive/c/deploy
rm -f sxs.tar.gz
/cygdrive/c/windows/sysnative/DISM.exe /Online /Enable-Feature /FeatureName:NetFx3 /All /Source:c:\\deploy\\sxs\\sxs
