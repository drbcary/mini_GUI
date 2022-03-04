

% Script to create plots and statistics from simple and complex output
% structures from Mini GUI program


set(0,'DefaultLineLineWidth',1.5,...
    'DefaultLineMarkerSize',8, ...
    'DefaultAxesLineWidth',2, ...
    'DefaultTextFontName','Arial',...
    'DefaultAxesFontSize',12,...
    'DefaultAxesBox','off',...
    'DefaultAxesFontWeight','Bold');


% Load analysis data .mat structures into the workspace, enter name of
% analysis structure for 'data_strct_comp' and run code.

% Enter the name of your COMPLEX (analysis) data structure here
data_strct_comp = SCTA_Output_Unblinded;

% Enter the name of your simple data structure here
% data_strct_sim = simple_output;


save_ON = 0;
username = getenv('USERNAME');
save_dir = ['C:' filesep 'Users' filesep username filesep 'Desktop' filesep]; % your save path here
save_formats = {'.fig','.tif','.pdf'};


cond_names = fields(data_strct_comp);

disp(['There are ',num2str(length(cond_names)),' conditions:'])
disp(cond_names)


Colors = hsv(length(cond_names));


% %make this based on formatting of simple output
% amp_col = 2;

%Find a number of ev's that works for all cells.
% num_events = 60; 

sample_rate = 10000;


amp_strct = {};
IEI_strct = {};

for cond_num = 1:length(cond_names)
    
%     cond_strct_sim = data_strct_sim.(char(cond_names{cond_num}));
    cond_strct_comp = data_strct_comp.(char(cond_names{cond_num}));
    cellnames = fields(cond_strct_comp);
    num_cells = length(cellnames);
    
    cond_amps = {};
    cond_IEI = {};
    
    for cell_num = 1:num_cells
        
        row = cell_num + 1;

        epsc_traces = cond_strct_comp.(char(cellnames(cell_num))).epsc_amps;
        cell_amps = [];
        for trace = 1:size(epsc_traces)
            cell_amps = [cell_amps epsc_traces{trace,2}];
        end
        
        trace_names = (cond_strct_comp.(char(cellnames(cell_num))).mini_data(:,1));
        cell_IEI_secs = [];
        for trace = 1:size(trace_names,1)
%             if ii == 1
%                 disp(['cell=',num2str(cell_num),' trace=',num2str(trace)])
%                 fprintf('\n');
%             end
            timeindx = cond_strct_comp.(char(cellnames(cell_num))).mini_data{trace, 2}.timeindx;
            timeindx = sort(timeindx);

            interval_times = [];
            interval_times = (timeindx(2:end) - timeindx(1:end-1))/sample_rate;

            cell_IEI_secs = [cell_IEI_secs interval_times];
        end        

        
        cond_amps{cell_num} = cell_amps;
        cond_IEI{cell_num} = cell_IEI_secs;
    end
    
    amp_strct{cond_num} = cond_amps;
    IEI_strct{cond_num} = cond_IEI;
end



%% Store data in matrices
num_conds = length(amp_strct);

for cond_num = 1:num_conds
    cond_strct = amp_strct{cond_num};
    cond_meas = [];
    for cell_num = 1:length(cond_strct)
        cond_meas = utils.padmat(cond_meas,cond_strct{cell_num}', 2);
    end
    eval(['Cell_evAmps_' cond_names{cond_num} '=cond_meas;'])
    
    cond_strct = IEI_strct{cond_num};
    cond_meas = [];
    for cell_num = 1:length(cond_strct)
        cond_meas = utils.padmat(cond_meas,cond_strct{cell_num}', 2);
    end
    eval(['Cell_IEIs_' cond_names{cond_num} '=cond_meas;'])    
end


%% PLOTTING %%
num_conds = length(amp_strct);


figure_coords = [300 400 140*num_conds 331];

% Plot amplitude averages
f1 = figure('Position',figure_coords);

data_toplot = [];
for cond_num = 1:num_conds
    cond_strct = amp_strct{cond_num};
    cond_meas = [];
    for cell_num = 1:length(cond_strct)
        cond_meas = utils.padmat(cond_meas,nanmean(cond_strct{cell_num})', 2);
    end
    data_toplot = utils.padmat(data_toplot, cond_meas', 2);
end


p1 = utils.UnivarScatter_Edit(data_toplot,'BoxType','SEM',...
    'Width',1.5,'Compression',35,'MarkerFaceColor',Colors,...
    'PointSize',35,'StdColor','none','SEMColor',[0 0 0],...
    'Whiskers','lines','WhiskerLineWidth',2,'MarkerEdgeColor',Colors);

box off
ylabel('mEPSC Amp. (pA)','FontSize',14)

set(gca,'XTickLabel',cond_names,'XTickLabelRotation',45,'FontSize',14);
xticks(1:num_conds)
xlim([0.5 num_conds+0.5])
ylim([0 max(max(data_toplot))*1.3])

title('Event amplitude cell averages','FontSize',12)

if save_ON == 1
    save_name = 'amp_avgs';
    for format = 1:size(save_formats,2)
        saveas(f1,[save_dir,filesep,save_name,save_formats{format}])
    end
end



% Plot freq averages

figure_coords = [500 400 140*num_conds 331];

f2 = figure('Position',figure_coords);

data_toplot = [];
for cond_num = 1:num_conds
    cond_strct = IEI_strct{cond_num};
    cond_meas = [];
    for cell_num = 1:length(cond_strct)
        cond_meas = utils.padmat(cond_meas,1/nanmean(cond_strct{cell_num})', 2);
    end
    data_toplot = utils.padmat(data_toplot, cond_meas', 2);
end

p1 = utils.UnivarScatter_Edit(data_toplot,'BoxType','SEM',...
    'Width',1.5,'Compression',35,'MarkerFaceColor',Colors,...
    'PointSize',35,'StdColor','none','SEMColor',[0 0 0],...
    'Whiskers','lines','WhiskerLineWidth',2,'MarkerEdgeColor',Colors);

box off
ylabel('mEPSC Freq. (Hz)','FontSize',14)

set(gca,'XTickLabel',cond_names,'XTickLabelRotation',45,'FontSize',14);
xticks(1:num_conds)
xlim([0.5 num_conds+0.5])
ylim([0 max(max(data_toplot))*1.3])

title('Event frequency cell averages','FontSize',12)


if save_ON == 1
    save_name = 'freq_avgs';
    for format = 1:size(save_formats,2)
        saveas(f2,[save_dir,filesep,save_name,save_formats{format}])
    end
end




% Cumulative amplitude plotting

% Calculate minimum random sample number
all_cell_evs = [];
for cond_num = 1:num_conds
    cond_strct = amp_strct{cond_num};
    for cell_num = 1:length(cond_strct)
        all_cell_evs = utils.padmat(all_cell_evs, cond_strct{cell_num}',2);
    end
end
min_num_evs = min(sum(~isnan(all_cell_evs)));
disp(['Cell with least number of events has ',num2str(min_num_evs)])
disp('Using this number for amplitude cumulative sampling...')

data_toplot = {};
for cond_num = 1:num_conds
    cond_strct = amp_strct{cond_num};
    cond_evs = [];
    for cell_num = 1:length(cond_strct)
        samp_evs = randsample(cond_strct{cell_num},min_num_evs);
        cond_evs = [cond_evs samp_evs];
    end
    data_toplot{cond_num} = cond_evs;
end

delta = 0.5;
xlim_up = round(max([data_toplot{:}])/10)*10;
for cond_num = 1:num_conds
    [X{cond_num} Y{cond_num}] = utils.cumhist(data_toplot{cond_num},[0 xlim_up], delta);
end

figure_coords = [350 150 486 365];
f3 = figure('Position',figure_coords);

for cond_num = 1:num_conds
    p{cond_num} = plot(X{cond_num}, Y{cond_num},'Color',Colors(cond_num,:),'LineWidth',2); hold on;
end

box off;
ylabel('Percentage','FontSize',12);
xlabel('Event Amplitudes (pA)','FontSize',12);
yticks(0:25:100)
xlim([0 xlim_up])
legend(cond_names,'Location','SouthEast')
% legend([p{:}],cond_names,'Location','SouthEast')

title('Amplitude Cumulative Hist','fontsize',12)


if save_ON == 1
    save_name = 'amp_cumul_hist';
    for format = 1:size(save_formats,2)
        saveas(f3,[save_dir,filesep,save_name,save_formats{format}])
    end
end


% Cumulative inter event interval plotting

% Calculate minimum random sample number
all_cell_evs = [];
for cond_num = 1:num_conds
    cond_strct = IEI_strct{cond_num};
    for cell_num = 1:length(cond_strct)
        all_cell_evs = utils.padmat(all_cell_evs, cond_strct{cell_num}',2);
    end
end
min_num_evs = min(sum(~isnan(all_cell_evs)));
disp(['Cell with least number of events has ',num2str(min_num_evs)])
disp('Using this number for IEI cumulative sampling...')

data_toplot = {};
for cond_num = 1:num_conds
    cond_strct = IEI_strct{cond_num};
    cond_evs = [];
    for cell_num = 1:length(cond_strct)
        samp_evs = randsample(cond_strct{cell_num},min_num_evs);
        cond_evs = [cond_evs samp_evs];
    end
    data_toplot{cond_num} = cond_evs.*1000;
end


delta = 0.5;
xlim_up = round(max([data_toplot{:}])/10)*10;
for cond_num = 1:num_conds
    [X{cond_num} Y{cond_num}] = utils.cumhist(data_toplot{cond_num},[0 xlim_up], delta);
end

figure_coords = [550 150 486 365];
f4 = figure('Position',figure_coords);

for cond_num = 1:num_conds
    p{cond_num} = plot(X{cond_num}, Y{cond_num},'Color',Colors(cond_num,:),'LineWidth',2); hold on;
end

box off;
ylabel('Percentage','FontSize',12);
xlabel('Inter mini interval (ms)','FontSize',12);
yticks(0:25:100)
xlim([0 xlim_up])
legend(cond_names,'Location','SouthEast')
% legend([p{:}],cond_names,'Location','SouthEast')

title('Inter-event Interval Cumulative Hist','fontsize',12)


if save_ON == 1
    save_name = 'interevent_cumul_hist';
    for format = 1:size(save_formats,2)
        saveas(f4,[save_dir,filesep,save_name,save_formats{format}])
    end
end












