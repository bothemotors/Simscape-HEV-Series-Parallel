%% SETUP MODEL FOR RSIM
HEV_Vehicle_Mass = HEV_Param.Vehicle.Mass;
HEV_Model_Driver_Ki = 0.04;
mdl = 'HEV_SeriesParallel';
open_system(mdl);

%% CONFIGURE FOR TEST
Select_HEV_Model_Systems('Sys BC VS',HEV_Configs);
set_param(mdl,'StopFcn',['%' get_param(mdl,'StopFcn')]);
set_param([mdl '/Vehicle Dynamics/Simple'],'mass','HEV_Vehicle_Mass');
set_param([mdl '/SLRT Scope'],'Commented','on');
save_system(mdl);

%% BUILD TARGET
rtp = Simulink.BlockDiagram.buildRapidAcceleratorTarget(mdl);

%% GENERATE PARAMETER SETS
Mass_array = [1000:100:1600]; 
SimSettings = Generate_Sim_Settings(Mass_array,'HEV_Vehicle_Mass',rtp);

numSims = length(SimSettings);
out = cell(1, numSims);

%% START PARALLEL POOL
parpool(2);
Initialize_MLPool

%% SIMULATE
tic;
parfor i = 1:numSims
    out{i} = sim(mdl, SimSettings{i});
end
Total_Testing_Time = toc;
disp(['Total Testing Time = ' num2str(Total_Testing_Time)]);

%% PLOT RESULTS
figure(1)
clf
set(gcf,'Position',[11   356   545   293]);

for i=numSims:-1:1
    data = out{i}.find('Motor');
    plot(data.time(:,1),data.signals(3).values(:,1),'LineWidth',2)
    hold all
end
title('Motor Torque','FontSize',16,'FontWeight','Bold');
xlabel('Time (s)','FontSize',12,'FontWeight','Bold');
ylabel('Motor Torque','FontSize',12,'FontWeight','Bold');
legend(cellstr(num2str(fliplr(Mass_array(1:1:end))')),'FontSize',10);

%% CLOSE PARALLEL POOL
delete(gcp);
HEV_Param.Control.Mode_Logic_TS = 0.1;

%% UNDO CONFIGURATION CHANGES, CLEANUP DIR 
stopfn_str = get_param(mdl,'StopFcn');
set_param(mdl,'StopFcn',stopfn_str(2:end));
set_param([mdl '/Vehicle Dynamics/Simple'],'mass','HEV_Param.Vehicle.Mass');
set_param([mdl '/SLRT Scope'],'Commented','off');
Select_HEV_Model_Systems('Sys BD VF',HEV_Configs);
save_system(mdl);
bdclose(mdl);
delete('*.mex*')
!rmdir slprj /S/Q

% Copyright 2013-2015 The MathWorks(TM), Inc.

