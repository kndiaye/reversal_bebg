% Synchro micromed
WriteParPort(0);
WaitSecs(1);
trand=rand;
tnow = now;
fname = sprintf('synchro_micromed_%s',datestr(tnow,30));
tsecs = GetSecs;
WriteParPort(255);
WaitSecs(.777);
WriteParPort(0);
save(fname,'tnow','tsecs','trand');

