function Mini_GUI_v5
% This is the work in progress mini and FI analysis GUI

%Author: Brian Cary of Turrigiano Lab (2018+; ~ongoing)

%Dependendicies: scrollplot, padmat, template_matching algorithm,
%get_PassProp_VC and get_PassProp_IC, ibwread


%% Variables

% Only matlab support currently
hs.mat_or_igor = 'MATLAB';

hs.mini_analysis_on = 1;

% optional root path for finding data
hs.data_path = 'C:\';

% set to '1' if you want to load previously analyzed save data to add to
% those structures
hs.LoadPrevSave_on = 0;

% Set to '1' to automatically load data from path below
hs.debug_on = 1;
hs.zDir = 'D:\Work\slice_data\5_7_18\';
hs.zFile = 'TraceData_5_7.mat';
% hs.zDir = 'C:\Users\bcary\Documents\Work\Data\Slice_Data\juliet\h5files\';
% hs.zFile = 'juliet_save.mat';
% hs.zDir = 'D:\Work\slice_data\3_16_17\';
% hs.zFile = 'Cell_0000001_0001.ibw';

%% initialize vars
% Important global variables that need to be set according to data
% collection parameters
hs.samp_rate = 10000; % !! Only sample rate of 10kHz has been tested !!

% seal test parameters
hs.analyze_seal_on   = 1;
hs.sealteststart     = 0.5; % in s
hs.sealtestlength    = 0.5; % in s
hs.sealtestend       = hs.sealteststart + hs.sealtestlength + 0.05; % in s
hs.sealtest_dvolt    = 0.005; % V
hs.sealtest_dcurr    = 100e-12; % pA

% fi mode (not implemented)
hs.fi_mode_on        = 0;
hs.step_interval     = [2,3];
hs.current_step_incr = 20; % in pA

% Default Filter parameters used in template matching
hs.filters.Smoothingfxn   = 1;
hs.filters.Ampthresh      = 5;

hs.filters.Templatethresh = 6.5;
hs.filters.Risetime       = 0.006;
hs.filters.Decaytime      = 0.005;
hs.filters.temp_length    = 20; % template length in ms!!
hs.filters.excisecoord    = [0,0];
hs.filters.pre_min_amp    = 5;
hs.filters.matching_skip  = 1;
hs.filters.epsc_yes       = 1;
hs.filters.samplerate     = hs.samp_rate;
hs.filters.AmpBiasCoeff   = 0.2;

% Initializes global variables used in program
hs.analysis_output        = struct;
hs.simple_output          = {};
hs.saved_run_num          = 0;
hs.have_analyzed          = 0;
hs.continue_yesno         = 0;
hs.excise_yesno           = 0;
hs.have_saved_yesno       = 0;
hs.excise_pts             = [];
hs.explore_plot_on        = 0;
hs.add_mini_pts           = [];
hs.rem_mini_pts           = [];
hs.num_save_later_files   = 0;
hs.time_scale             = 1000/hs.samp_rate; %because sampling is 10kHz and I want time in ms
hs.amp_scale              = 10^12;
hs.remove_seal_yesno      = 0;
hs.analyzed_trace         = 1;
hs.current_filename       = {};
hs.saved_filenames        = {};
hs.ax                     = [];
hs.remove_60hz_yesno      = 0;
hs.y_scale_factor         = 1;
hs.mini_ylims             = [-30, 10];
hs.ep_ipsc                = 1; %1 = epsc, 2 = ipsc
hs.savedata               = {};

% acquire screen size parameters
screen_size = get(0,'ScreenSize');
hs.s_wid = screen_size(3);
hs.s_ht = screen_size(4);

warning('off', 'MATLAB:ui:javaframe:PropertyToBeRemoved')

%% GUI %%

% Loads blank slate GUI with buttons
function make_GUI 
hs.fig = figure('Visible','on','NumberTitle','off',...
    'Color',[.75 .75 .9],'Position',[.125*hs.s_wid .25*hs.s_ht .75*hs.s_wid .65*hs.s_ht],...
    'KeyPressFcn', @key_catcher);

% Initial panel giving first three options
hs.panel = uipanel(hs.fig, 'BorderType', 'none',...
        'Position',[.25 .1 .5 .8]);

hs.setparam_but = uicontrol(hs.panel,'Style','pushbutton','String','Set Parameters',...
        'Units','normalized', 'Callback', @setparam,...
        'Position',[.3 .8 .4 .1]);

hs.loadparam_but = uicontrol(hs.panel,'Style','pushbutton','String','Load Parameters',...
        'Units','normalized', 'Callback', @loadparam,...
        'Position',[.3 .45 .4 .1]);

hs.explore_data_but = uicontrol(hs.panel,'Style','pushbutton','String',...
        'Explore Data',...
        'Units','normalized', 'Callback', @explore_data,...
        'Position',[.3 .1 .4 .1]);
   
% Pick data folder
hs.pickdatafolder_but = uicontrol('Style','pushbutton','String','Select folder containing data',...
        'Units','normalized', 'Callback', @pickdatafolder,...
        'Position',[.4 .5 .2 .1],...
        'Visible', 'off');
    
% Pick folder with condition for data
hs.choosecond_but = uicontrol('Style','pushbutton',...
        'String', ['Choose folder with condition ' num2str(1) ' data'],...
        'Units','normalized', 'Callback', @choosecond,...
        'Position',[.4 .5 .2 .1],...
        'Visible', 'off');

% See raw data
hs.seerawdata_but = uicontrol('Style','pushbutton',...
        'String', 'See raw data',...
        'Units','normalized', 'Callback', @seerawdata,...
        'Position',[.6 .5 .2 .1],...
        'Visible', 'off');
    
hs.analyze_but = uicontrol('Style','pushbutton',...
        'String','Analyze Now! [\]',...
        'Units','normalized', 'Callback', @mini_analysis,...
        'Position',[.85 .75 .1 .05],...
        'Visible', 'off');
    
hs.excise_but = uicontrol('Style','pushbutton',...
        'String','Excise [L]',...
        'Units','normalized', 'Callback', @excise_but,...
        'Position',[.85 .68 .1 .05],...
        'Visible', 'off');
    
hs.add_mini_but = uicontrol('Style','pushbutton',...
        'String','Add Mini [P]',...
        'Units','normalized', 'Callback', @add_mini_but,...
        'Position',[.85 .61 .1 .05],...
        'Visible', 'off');
    
hs.rem_mini_but = uicontrol('Style','pushbutton',...
        'String','Remove Mini [O]',...
        'Units','normalized', 'Callback', @rem_mini_but,...
        'Position',[.85 .54 .1 .05],...
        'Visible', 'off');
    
    
hs.ep_ipsc_but = uicontrol('Style','pushbutton',...
        'String','EPSC/IPSC []',...
        'Units','normalized', 'Callback', @ep_ipsc_but,...
        'Position',[.85 .47 .1 .05],...
        'Visible', 'off');
    
hs.cell_jump_box = uicontrol(hs.fig,'style','edit',...
    'Units','normalized',...
    'string', '1',...
    'FontSize', 14,...
    'Position', [.83 .35 .05 .05],...
    'Visible', 'on');
    
hs.cell_jump_but = uicontrol('Style','pushbutton',...
        'String','Jump to Cell',...
        'Units','normalized', 'Callback', @cell_jump_but,...
        'Position',[.91 .35 .05 .05],...
        'Visible', 'off');
    
hs.cell_group_label = uicontrol(hs.fig,'style','text',...
    'string','Cell Group',...
    'Units','normalized',...
    'Position', [.85 .25 .13 .03],...
    'FontSize', 14,...
    'Visible', 'on');

hs.cell_group_box = uicontrol(hs.fig,'style','edit',...
    'Units','normalized',...
    'string', 'CONT',...
    'FontSize', 14,...
    'Position', [.85 .22 .13 .03],...
    'Visible', 'on');

hs.cell_save_label = uicontrol(hs.fig,'style','text',...
    'string','Cell save name',...
    'Units','normalized',...
    'Position', [.85 .18 .13 .03],...
    'FontSize', 14,...
    'Visible', 'off');

hs.cell_save_name_box = uicontrol(hs.fig,'style','edit',...
    'Units','normalized',...
    'string', 'cell1',...
    'FontSize', 14,...
    'Position', [.85 .15 .13 .03],...
    'Visible', 'off');
     
hs.continue_but = uicontrol('Style','pushbutton',...
        'String', 'Continue [+]',...
        'Units','normalized', 'Callback', @continue_but,...
        'Position',[.91 .82 .075 .1],...
        'Visible', 'off'); 
    
hs.back_but = uicontrol('Style','pushbutton',...
        'String', 'Back [-]',...
        'Units','normalized', 'Callback', @back_but,...
        'Position',[.83 .82 .075 .1],...
        'Visible', 'off');     
  
hs.rem_seal_but = uicontrol('Style','pushbutton',...
        'String', 'Remove Seal',...
        'Units','normalized', 'Callback', @rem_seal_but,...
        'Position',[.12 .918 .09 .05],...
        'Visible', 'off');   
    
hs.save_this_data_but = uicontrol('Style','pushbutton',...
        'String','Save Data ( ] )',...
        'Units','normalized', 'Callback', @save_this_data_but,...
        'Position',[.875 .025 .1 .1],...
        'Visible', 'off','FontSize', 14,...
        'FontWeight', 'bold',...
        'BackgroundColor', [.1 .8 .2]);
    
hs.loading_text = uicontrol('Style', 'text', 'Units', 'normalized',...
       'string', 'Loading...','Position',...
       [0.4 0.5 0.1 0.05], 'Visible', 'off');    
     
   
%%%%%%%%%%%%%%%%%
%Fi gui stuff

hs.step_int_label = uicontrol(hs.fig,'style','text',...
    'string','Current Interval ([1,2; 3,4])',...
    'Units','normalized',...
    'Position', [.85 .74 .1 .06],...
    'FontSize', 14,...
    'Visible', 'off');

hs.current_step_int_box = uicontrol(hs.fig,'style','edit',...
    'Units','normalized',...
    'string', '[2,3]',...
    'FontSize', 14,...
    'Position', [.85 .7 .1 .03],...
    'Visible', 'off');

hs.analyze_fi_but = uicontrol(hs.fig, 'Style','pushbutton',...
        'String','Analyze FI Now! [\]',...
        'Units','normalized', 'Callback', @analyze_fi,...
        'Position',[.85 .5 .1 .1],...
        'Visible', 'off');
    
hs.step_current_label = uicontrol(hs.fig,'style','text',...
    'string','Step Current (pA)',...
    'Units','normalized',...
    'Position', [.85 .4 .1 .03],...
    'FontSize', 14,...
    'Visible', 'off');   

hs.step_current_box = uicontrol(hs.fig,'style','edit',...
    'Units','normalized',...
    'string', '20',...
    'FontSize', 14,...
    'Position', [.85 .35 .1 .03],...
    'Visible', 'off');

end

% Param GUI
function make_param_GUI
    
    hs.param_fig = figure('Visible','on','NumberTitle',...
        'off','Color',[.8 .85 .85],...
        'Units', 'normalized',...
        'Position',[0.0182 0.1481 0.2266 0.7000],...
        'Visible', 'off'); 
        
    uicontrol(hs.param_fig,'style','text',...
        'string','Parameters',...
        'Units','normalized',...
        'Position', [.05 .92 .3 .075],...
        'FontSize', 16,...
        'Visible', 'on');
    
    uicontrol(hs.param_fig,'style','text',...
        'string','Template Threshold',...
        'Units','normalized',...
        'Position', [.05 .85 .3 .03],...
        'FontSize', 12,...
        'Visible', 'on');
        
    hs.temp_thresh_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.filters.Templatethresh),...
        'FontSize', 14,...
        'Position', [.5 .85 .3 .05],...
        'Visible', 'on');
    
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Rise Time (s)',...
        'Units','normalized',...
        'Position', [.05 .79 .3 .03],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.risetime_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.filters.Risetime),...
        'Position', [.5 .78 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Pre-Match min. ampl.',...
        'Units','normalized',...
        'Position', [.05 .71 .3 .06],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.pre_min_amp_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.filters.pre_min_amp),...
        'Position', [.5 .71 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Post-Match min. ampl.',...
        'Units','normalized',...
        'Position', [.05 .63 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.post_min_amp_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.filters.Ampthresh),...
        'Position', [.5 .63 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Large Amp. Bias Coeff.',...
        'Units','normalized',...
        'Position', [.05 .56 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.amp_bias_coeff_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.filters.AmpBiasCoeff),...
        'Position', [.5 .56 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string',{'Sealtest Amp.';'(mv or pa)'},...
        'Units','normalized',...
        'Position', [.05 .49 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.sealtest_amp_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.sealtest_dvolt),...
        'Position', [.5 .49 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    
    %%%
    hs.avg_temp_but = uicontrol(hs.param_fig,'style','togglebutton',...
        'string','Avg. Template',...
        'Units','normalized',...
        'Callback', @avg_temp_but,...
        'Position', [.5 .36 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');

    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Yaxis Limit [min,max]',...
        'Units','normalized',...
        'Position', [.05 .29 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.mini_ylims_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', num2str(hs.mini_ylims),...
        'Position', [.42 .29 .22 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    uicontrol(hs.param_fig,'style','pushbutton',...
        'string','Apply',...
        'Units','normalized',...
        'Callback', @apply_ylim_but,...
        'Position', [.7 .29 .2 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    
    %%%
    uicontrol(hs.param_fig,'style','text',...
        'string','Man. Gain',...
        'Units','normalized',...
        'Position', [.05 .22 .3 .05],...
        'FontSize', 12,...
        'Visible', 'on');
    
    hs.apply_gain_box = uicontrol(hs.param_fig,'style','edit',...
        'Units','normalized',...
        'string', '1',...
        'Position', [.42 .22 .22 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    uicontrol(hs.param_fig,'style','pushbutton',...
        'string','Apply',...
        'Units','normalized',...
        'Callback', @apply_gain_but,...
        'Position', [.7 .22 .2 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    hs.remove_60hz_but = uicontrol(hs.param_fig,'style','togglebutton',...
        'string','Remove 60Hz',...
        'Units','normalized',...
        'Callback', @remove_60hz_but,...
        'Position', [.65 .08 .3 .05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    
    uicontrol(hs.param_fig,'style','pushbutton',...
        'string','Re-Explore',...
        'Units','normalized',...
        'Callback', @explore_data,...
        'Position', [.05 .05 .3 .1],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
    
    hs.igor_or_mat_menu = uicontrol(hs.param_fig,'style','popupmenu',...
        'string',{'Igor','Matlab'},...
        'Value',2,...
        'Units','normalized',...
        'Callback', @file_type,...
        'Position', [.36 .075 .25 0.05],...
        'FontSize', 14,...
        'Visible', 'on');
    %%%
end

% Makes new figure used for visualizing saved traces
function make_save_fig
    hs.save_fig = figure('Visible','on','NumberTitle','off',...
        'Units', 'normalized',...
        'Color',[.8 .93 .82],'Position',[0.81 0.15 0.15 0.6],...
        'Visible', 'off'); 

    hs.stored_title = uicontrol(hs.save_fig,'style','text',...
        'string','Mini Files Stored',...
        'Units','normalized',...
        'Position', [.05 .92 .3 .075],...
        'FontSize', 18,...
        'Visible', 'on');

    hs.saved_title = uicontrol(hs.save_fig,'style','text',...
        'string','Mini Files Saved',...
        'Units','normalized',...
        'Position', [.05 .92 .3 .075],...
        'FontSize', 18,...
        'Visible', 'off');

    hs.saved_filenames_box = uicontrol(hs.save_fig, 'style', 'text',...
        'string', ' ',...
        'Units', 'normalized',...
        'Position', [.08 .1 .8 .8],...
        'FontSize', 18,...
        'Visible', 'on');
end

    
%% Start Program

if hs.mini_analysis_on == 0
    disp('Set to not analyze minis')
end

if hs.analyze_seal_on == 1
    disp('---Set to automatically analyze a seal test (square voltage step) for each trace---')
    disp('Seal test has these parameters for each trace: ')
    disp(['Seal test starts at ',num2str(hs.sealteststart) ' sec'])
    disp(['Seal test is ',num2str(hs.sealtestlength) ' sec long'])
    disp(['Seal test delivers ',num2str(hs.sealtest_dvolt) ' volt step'])
    disp('If these paramaeters are incorrect or you do not wish to analyze a seal test per trace,')
    disp('You can find and change these variables in the beginning of the code.')
    disp('e.g. you can prevent sealtest analysis by changing hs.analyze_seal_on to 0')
    disp('---')
end

% Make the first gui windows
make_param_GUI
make_GUI
make_save_fig

% load data for first time
explore_data

disp('SELECT folder to save files in...')
if hs.debug_on == 1
    if ~isempty(hs.data_path)
        hs.SaveDir = hs.data_path;
    end
else
    if ~isempty(hs.data_path)
        [hs.SaveDir] = uigetdir(hs.data_path,'SELECT folder to save files in...');
    else
        [hs.SaveDir] = uigetdir('','SELECT folder to save files in...');
    end
end

% Allows you to choose previoulsy made saved analysis with both 'simple'
% and 'complex/full' components
if hs.LoadPrevSave_on == 1
    disp('SELECT previous analysis save file...')
    disp('Save file must contain COMPLEX and SIMPLE variables!')

    try
        [prevsimp_file, prevsimpe_path] = uigetfile();
        [prevsave] = open([prevsimpe_path prevsimp_file]);

        prevsave_fields = fieldnames(prevsave);
        prevsave1 = prevsave.(char(prevsave_fields(1)));
        prevsave2 = prevsave.(char(prevsave_fields(2)));
        
        prevsave1_fields = fieldnames(prevsave1);
        if isstruct(prevsave1.(char(prevsave1_fields(1))))
            hs.analysis_output = prevsave1;
            hs.simple_output = prevsave2;
        else
            hs.analysis_output = prevsave2;
            hs.simple_output = prevsave1;
        end
        
        disp('Save Cell Groups names are...')
        disp(fieldnames(hs.simple_output))

    catch ME
        fprintf(['Error loading previous file saves: ', '\n'])
        disp(ME)
    end

end
   

%% Functions

%%%%%%%%%%%%%%%%%%
% Functions
%%%%%%%%%%%%%%%%%%

% Turns buttons on and load first trace
function explore_data(~, ~)
    
    if ~isvalid(hs.fig)
        make_GUI
    end
        
    hs.panel.Visible = 'off';
    hs.continue_but.Visible = 'on';
    hs.back_but.Visible = 'on';
    hs.excise_but.Visible = 'on';
    hs.analyze_but.Visible = 'on';
    hs.param_fig.Visible = 'on';
    hs.add_mini_but.Visible = 'on';
    hs.rem_mini_but.Visible = 'on';
    hs.save_this_data_but.Visible = 'on';
    hs.rem_seal_but.Visible = 'on';
    hs.cell_save_label.Visible = 'on';
    hs.cell_save_name_box.Visible = 'on';
    hs.ep_ipsc_but.Visible = 'on';
    hs.cell_jump_but.Visible = 'on';
    
    if strcmp(hs.mat_or_igor, 'MATLAB')
        if hs.debug_on == 1
            disp('Debug Mode ON...')
        else
            [hs.zFile, hs.zDir] = uigetfile('*.mat','Select folder with mini data');
        end
        
        hs.full_data = load([hs.zDir, hs.zFile]);
        data_struct_name = fields(hs.full_data);
        hs.full_data = hs.full_data.(char(data_struct_name));
        hs.cell_names = (fields(hs.full_data));

        hs.trace_ind = 1;
        hs.cell_ind = 1;
        hs.cell_data = hs.full_data.(char(hs.cell_names(hs.cell_ind)));

        hs.data_y_inA = hs.cell_data.data(hs.trace_ind,2);
        hs.data_y_inA = hs.data_y_inA{1}.*10^-12;        

    else
        if hs.debug_on == 1
            disp('Debug Mode ON...')
        else
            [hs.zFile, hs.zDir] = uigetfile('*.ibw','Select folder with mini data');
        end        
        hs.file_names = dir(fullfile(hs.zDir, '*.ibw'));

        name_strs = cell(1, length(hs.file_names));
        for trace = 1:length(hs.file_names)
            name_strs{trace} = hs.file_names(trace).name;
        end

        hs.trace = find(strcmp(name_strs,hs.zFile));
        hs.data = utils.IBWread([hs.zDir, hs.file_names(hs.trace).name]);
        hs.data_y_inA = hs.data.y;
        if ~(hs.samp_rate == (1 / hs.data.dx))
            disp('Error: hardcoded sample rate does not match IBW file metadata')
            keyboard
        end
    end

    hs.time_scale = 1000 / hs.filters.samplerate;
    explore_plot(hs.data_y_inA)

end

%%%%%%%%%%%%%%%%%%

% Proceed to the next trace
function continue_but(~,~)
    try
        
    % clear of sub_fig axis (found that some RAM is eaten up otherwise)
    try
        cla(hs.sub_fig)
        hs = rmfield(hs,'sub_fig');
    end
    hs.have_analyzed = 0;
    hs.remove_seal_yesno = 0;
    
    % Load in data from next trace. This will be unique depending on how
    % your data is stored/structured.
    if strcmp(hs.mat_or_igor, 'MATLAB')
        
        if ~isfield(hs,'full_data')
            hs.full_data = load([hs.zDir, hs.zFile]);
            data_struct_name = fields(hs.full_data);
            hs.full_data = hs.full_data.(char(data_struct_name));        
            hs.cell_data = hs.full_data.(char(hs.cell_names(hs.cell_ind)));
        end
        
        if hs.trace_ind < length(hs.cell_data.data(:,1))
            hs.trace_ind = hs.trace_ind + 1;
        else
            if hs.cell_ind < length(hs.cell_names)
                hs.trace_ind = 1;
                hs.cell_ind = hs.cell_ind + 1;
                hs.cell_data = hs.full_data.(char(hs.cell_names(hs.cell_ind)));
            end
                
        end
        
        hs = rmfield(hs,'data_y_inA');
        hs.data_y_inA = hs.cell_data.data(hs.trace_ind,2);
        hs.data_y_inA = hs.data_y_inA{1}.*10^-12;
        
    else
        if hs.trace < length(hs.file_names)
            hs.trace = hs.trace + 1;
        end

        fclose('all');
        hs.data = utils.IBWread([hs.zDir, hs.file_names(hs.trace).name]);
        hs.data_y_inA = hs.data.y;
    end
    
    hs.sub_fig = subplot('Position',[.05 .2 .75 .6],'visible','on','Parent',hs.fig);
    explore_plot(hs.data_y_inA)
    
    if hs.fi_mode_on == 1
        step_cur = get(hs.step_current_box,'string');
        step_cur = str2num(step_cur);
        step_cur(step_cur==' ') = '';
        
        step_cur = step_cur + hs.current_step_incr;
        
        hs.step_current_box.String = num2str(step_cur);

    end
    
    catch
        disp('continue button error')
    end
end

%%%%%%%%%%%%%%%%%%

% Proceed to the previous trace (very similar to next_but)
function back_but(~,~)
    try
    hs.have_analyzed = 0;
    hs.remove_seal_yesno = 0;
    cla(hs.sub_fig)
    hs = rmfield(hs,'sub_fig');
    
    if strcmp(hs.mat_or_igor, 'MATLAB')
        
        if ~isfield(hs,'full_data')
            hs.full_data = load([hs.zDir, hs.zFile]);
            data_struct_name = fields(hs.full_data);
            hs.full_data = hs.full_data.(char(data_struct_name));        
            hs.cell_data = hs.full_data.(char(hs.cell_names(hs.cell_ind)));
        end
        
        if hs.trace_ind > 1
            hs.trace_ind = hs.trace_ind - 1;
        else
            if hs.cell_ind > 1
                hs.trace_ind = length(hs.full_data.(char(hs.cell_names(hs.cell_ind-1))).data(:,1));
                hs.cell_ind = hs.cell_ind - 1;
            else
                disp('first cell')
            end
        end
        hs.cell_data = hs.full_data.(char(hs.cell_names(hs.cell_ind)));
        hs.data_y_inA = hs.cell_data.data(hs.trace_ind,2);
        hs.data_y_inA = hs.data_y_inA{1}.*10^-12;       
    else
        if hs.trace > 1
            hs.trace = hs.trace - 1;
        end
        fclose('all');
        hs.data = utils.IBWread([hs.zDir, hs.file_names(hs.trace).name]);
        hs.data_y_inA = hs.data.y;        
    end
    
    hs.sub_fig = subplot('Position',[.05 .2 .75 .6],'visible','on','Parent',hs.fig);

    if hs.fi_mode_on == 1
        step_cur = get(hs.step_current_box,'string');
        step_cur = str2num(step_cur);
        step_cur(step_cur==' ') = '';
        
        step_cur = step_cur - hs.current_step_incr;
        
        hs.step_current_box.String = num2str(step_cur);
    end
    
    explore_plot(hs.data_y_inA)
    catch
        disp('back button error')
    end
    
end

%%%%%%%%%%%%%%%%%%

% Removes sections of trace that are not analyzable
function excise_but(~,~)
    try
    cla
    to_remove = [];
    excised_data_x = [];

    if size(hs.excise_pts,2) > 1
    for exc_num = 1:size(hs.excise_pts, 1)

        exc_st = hs.excise_pts(exc_num, 1);
        exc_end = hs.excise_pts(exc_num, 2);

        excise_int = (exc_st*1/(hs.time_scale)):...
            (exc_end*1/(hs.time_scale));

        to_remove = [to_remove, excise_int];
    end
    end
    
    
    hs.excise_pts = [];
    if hs.have_analyzed == 0
        hs.data_y_inA(round(to_remove)) = [];
        explore_plot(hs.data_y_inA) 
    else
        hs.data_y_inA(round(to_remove)) = [];
        mini_analysis('plot')
    end
    
    catch
        disp('excise data button error')
    end

end

%%%%%%%%%%%%%%%%%%

% Plots trace
function explore_plot(data_to_plot) % This plot function accepts data in base units (V or A) no scaling
    try
    hs.explore_plot_on = 1;
    hs.sub_fig = subplot('Position',[.07 .1 .75 .8],'visible','on','Parent',hs.fig);
    axes(hs.sub_fig);
    scaled_x = (0:length(data_to_plot)-1).*hs.time_scale;
    
    if strcmp(hs.mat_or_igor, 'MATLAB')
        this_trace_meta = hs.cell_data.metadata{hs.trace_ind,2};
        clamp_string = this_trace_meta{2,1};
        if contains(clamp_string, 'Iclamp')
            hs.y_units = 'V';
        else
            hs.y_units = 'A';
        end
        
        cell_name = hs.cell_data.data(hs.trace_ind,1);
        if length(cell_name{1}) == 3
            hs.current_filename = char([cell_name{1}{1},...
                cell_name{1}{2},...
                cell_name{1}{3}]);
        else
            hs.current_filename = char(cell_name);
        end

    else
        hs.y_units = hs.data.waveHeader.dataUnits;
        hs.current_filename = hs.file_names(hs.trace).name;
    end
    
    if hs.y_units == 'A'
        %convert to pA's. I need to do for my data. Didn't for test trace
        hs.y_scale_factor = 10^12;
        scaled_y = data_to_plot*hs.y_scale_factor;
        data_to_plot = [];
        data_plot = plot(hs.sub_fig, scaled_x, scaled_y, 'k'); 
        hold(hs.sub_fig,'on')
        ylabel(hs.sub_fig,'Current (pA)')
        
        if hs.ep_ipsc == 1
            titlename = [strrep(hs.current_filename,'_',' ') ': ' '{\color[rgb]{0.1 0.8 0.2}EPSC Detection}'];
            title(hs.sub_fig, titlename,'interpreter','tex')
        else
            titlename = [strrep(hs.current_filename,'_',' ') ': ' '{\color[rgb]{0 0 1}IPSC Detection}'];
            title(hs.sub_fig, titlename,'interpreter','tex')
        end
        
        mini_mode
    end
       
    if hs.y_units == 'V'
        hs.y_scale_factor = 10^3;
        scaled_y = data_to_plot*hs.y_scale_factor;
        data_to_plot = [];
        data_plot = plot(hs.sub_fig, scaled_x, scaled_y, 'k');
        hold(hs.sub_fig,'on')
        ylabel(hs.sub_fig,'Voltage (mV)')
        fi_mode()
    end
    
    if hs.remove_seal_yesno == 0
        sealtest_idx = hs.sealtestend*1000;
        hs.sealtest_line = plot([sealtest_idx sealtest_idx], [min(scaled_y), max(scaled_y)], '--r');
    end
    
    hold(hs.sub_fig,'off')
    box off
    set(hs.sub_fig, 'FontSize', 18)
    xlabel(hs.sub_fig,'Time (ms)')
    utils.scrollplot(data_plot)
    
    catch ME
        fprintf(['Explore plot error (data viewer function): ', '\n']);
        disp(ME)
    end


end

%%%%%%%%%%%%%%%%%%

% Remove detected individual mini events from being analyzed
function rem_mini_but(~,~)    
    
    try
    excisecoord = [];
    if size(hs.rem_mini_pts,2) > 1
    for exc_num = 1:size(hs.rem_mini_pts, 1)

        exc_st = hs.rem_mini_pts(exc_num, 1);
        exc_end = hs.rem_mini_pts(exc_num, 2);
        
        exc_st = (exc_st*1/(hs.time_scale));
        exc_end = (exc_end*1/(hs.time_scale));
        
        excisecoord(exc_num, 1) = exc_st;
        excisecoord(exc_num, 2) = exc_end;
    end
    end
        
    hs.rem_mini_pts = [];
    for coord_pair = 1:size(excisecoord,1)
    minis_to_remove = (find(hs.thiscell.timeindx > excisecoord(coord_pair,1) & ...
    hs.thiscell.timeindx < excisecoord(coord_pair,2)));
    end
    
    hs.thiscell.timeindx(minis_to_remove) = [];
    hs.thiscell.sm_pk_ind(minis_to_remove) = [];
    hs.thiscell.event_start_ind(minis_to_remove) = [];
    hs.thiscell.amp(minis_to_remove) = [];
    hs.thiscell.events(:,minis_to_remove) = [];
    hs.thiscell.decay_ind(minis_to_remove) = [];
    hs.thiscell.risetime(minis_to_remove) = [];

    %Save
%     cell_save_name = get(hs.cell_save_name_box,'string');
%     cell_save = hs.analysis_output.(cell_save_name);
%     cell_save.mini_data{end,2} = hs.thiscell;
%     if hs.ep_ipsc == 1
%         cell_save.epsc_amps{end,2} = hs.thiscell.amp;
%     else
%         cell_save.ipsc_amps{end,2} = hs.thiscell.amp;
%     end
%     hs.analysis_output.(cell_save_name) = cell_save;

    ax = gca;
    hs.ax = [ax.XLim ax.YLim];
    plot_mini_analysis()
    catch
        disp('remove mini button error')
    end
    
end

%%%%%%%%%%%%%%%%%%

% Attempt to add an individual mini event that was not detected
% automatically
function add_mini_but(~,~)
      
    try
    if size(hs.add_mini_pts,2) > 1
        for add_num = 1:size(hs.add_mini_pts, 1)

            add_st = hs.add_mini_pts(add_num, 1);
            add_end = hs.add_mini_pts(add_num, 2);

            add_int = (add_st*1/(hs.time_scale)):...
                (add_end*1/(hs.time_scale));

        end
    end
    
    hs.add_mini_pts = [];
    added_event = hs.analyzed_data_y(round(add_int));
    
    %%%%%%%%%%%%%%
    %assignin('base', 'broke_mini_2',added_event)
    %%%%%%%%%%%%%%
    
    %%
    max_rise = 0.008*hs.samp_rate;
    mini_threshold = 4*10^-12; % threshold for detecting mini peak used here
    smooth_event = sgolayfilt(added_event, 2, 15); % smooths event with polynomial 2, window size 13
    offset_smooth_event = smooth_event - mean(smooth_event(1:15));
    int_st = 0.0005*hs.samp_rate;
    int_end = 0.0150*hs.samp_rate;
    try
        [min_pks, min_locs] = findpeaks(-offset_smooth_event, 'MinPeakHeight', mini_threshold); % finds 
    catch
        [min_pks, min_locs] = min(offset_smooth_event);
    end

    if isempty(min_locs) == 1
        [min_pks, min_locs] = min(offset_smooth_event(int_st:int_end));
    end
    [largest_pk, largest_ind] = max(min_pks);
%     
%     if min_pks(1) > 0.7*largest_pk
%         mini_pk_loc = min_locs(1); %pick first peak
%     else
%         mini_pk_loc = min_locs(largest_ind);
%     end
    mini_pk_loc = min_locs(find(min_pks > 0.75*largest_pk, 1));
    
    %find pre-rise pk before mini pk
    %max_rise = 120;
    % make sure you don't index out of bounds
    if max_rise >= mini_pk_loc
        max_rise = mini_pk_loc - 1;
    end
    
    %%%%
    
    try
        [max_pks, max_locs] = findpeaks(smooth(added_event(mini_pk_loc-max_rise:mini_pk_loc),1));
    catch
        [max_pks, max_locs] = max(smooth_event(mini_pk_loc-max_rise:mini_pk_loc));
    end

    if isempty(max_locs) == 1
        [max_pks, max_locs] = max(smooth_event(mini_pk_loc-max_rise:mini_pk_loc));
    end

    peak_found = 1;

    pks_above_std = max_locs(max_pks >= median(max_pks));
    if numel(pks_above_std) > 1
        pre_pk_loc = round((pks_above_std(end-1)+pks_above_std(end))/2);
    elseif numel(pks_above_std) == 1
        pre_pk_loc = pks_above_std;
    elseif numel(pks_above_std) < 1
        pre_pk_loc = 1;
    end
    
    pre_pk_val = nanmean([nanmean(added_event(1:pre_pk_loc)),...
        nanmedian(added_event(1:pre_pk_loc))]);
    if peak_found == 1
        event_start_ind = (mini_pk_loc - max_rise + pre_pk_loc - 1); %pick last one and find time to beginning

        event_start_val = pre_pk_val;

        if mini_pk_loc-20 < 1
            mini_pk_loc = 21;
        end

        [sm_pk_val,sm_pk_ind] = min(smooth_event((mini_pk_loc-20:mini_pk_loc+30))); 
        %find min around peak and report val and ind using 3pt moving average

        sm_pk_ind = mini_pk_loc - 20 + sm_pk_ind - 1; % correct placement
        sm_pk_val = abs(sm_pk_val) + event_start_val;
        
        if isempty(event_start_ind) == 1
            event_start_ind = 1;
        end
        if isnan(sm_pk_ind) == 0

            % find where mini has decreased by 90% from peak
            decay_loc = find((smooth_event(sm_pk_ind:end) - event_start_val)...
                > -0.2*sm_pk_val, 1, 'first');

            if isempty(decay_loc) == 0
                decay_ind = decay_loc + sm_pk_ind - 1;
            else
                %Roughest error catch
                decay_ind = length(added_event) - 1;
            end

            %Find peak again after having found decay pt
            first_sm_pk_ind = sm_pk_ind;
            
            super_smooth_event = smooth(smooth_event,3);
            try
                [sm_pk_val,sm_pk_ind] = min(super_smooth_event(first_sm_pk_ind-20:...
                    decay_ind));
            catch
                [sm_pk_val,sm_pk_ind] = min(super_smooth_event(1:...
                    decay_ind));
            end

            sm_pk_ind = first_sm_pk_ind - 20 + sm_pk_ind - 1; % correct placement
            sm_pk_val = abs(sm_pk_val) + event_start_val;
            
            rise_time = sm_pk_ind - event_start_ind;
            
            decay_loc = find((smooth_event(sm_pk_ind:end) - event_start_val)...
                > -0.2*sm_pk_val, 1, 'first');

            if decay_loc > 180
                decay_loc = find((smooth_event(sm_pk_ind:end) - event_start_val)...
                > -0.25*sm_pk_val, 1, 'first');
            end

            if isempty(decay_loc) == 0
                decay_ind = decay_loc + sm_pk_ind;
            else
                %Roughest error catch
                decay_ind = length(added_event) - 1;
            end

        end

    end

    %% Add data and plot
    %%%%%%%%%%%%
    try
        raw_data = hs.thiscell.DATA.*hs.amp_scale;
        shifted_added_event = raw_data(round(add_int))-event_start_val;
        smooth_event = smooth_event - event_start_val;
        slope = sm_pk_val/(1000*(sm_pk_ind - event_start_ind)/hs.samp_rate);
        pk_val = sm_pk_val;
        mini_fig = figure('Units', 'normalized',...
            'Position',[0.3 0.15 0.25 0.75]);
        
        mini_ax = axes(mini_fig);
        plot(mini_ax,shifted_added_event,'k','LineWidth',0.7)
        hold on;
        plot(mini_ax,smooth(shifted_added_event,10),'r','LineWidth',1.5)
        plot(mini_ax,event_start_ind, smooth_event(event_start_ind), 'gx','MarkerSize',16)
        plot(mini_ax,sm_pk_ind, -sm_pk_val, 'bx','MarkerSize',16)
        plot(mini_ax,decay_ind, smooth_event(decay_ind), 'rx','MarkerSize',16)
        text(mini_ax,1, min(shifted_added_event), ['Amp = ', num2str(sm_pk_val)],'FontSize',18)
        text(mini_ax,(length(shifted_added_event)/2+10), min(shifted_added_event), ['Rise = ', num2str(rise_time/hs.samp_rate)],'FontSize',18)
        text(mini_ax,1, abs(pk_val/2), ['Slope = ', num2str(slope)],'FontSize',18)
    catch
        mini_fig = figure;
    end
    
    [~,~,BUTTON] = ginput(1);
    
    
    
    close(mini_fig)
    if BUTTON==112
        hs.thiscell.risetime = [hs.thiscell.risetime, rise_time];
        hs.thiscell.timeindx = [hs.thiscell.timeindx, round(add_int(1))];
        hs.thiscell.amp = [hs.thiscell.amp,sm_pk_val];
        hs.thiscell.event_start_ind = [hs.thiscell.event_start_ind, event_start_ind];
        hs.thiscell.events = padmat(hs.thiscell.events, added_event./hs.amp_scale, 2);
        hs.thiscell.sm_pk_ind = [hs.thiscell.sm_pk_ind, sm_pk_ind];
        hs.thiscell.decay_ind = [hs.thiscell.decay_ind, decay_ind];
                
        %Save
        
%         
%         cell_save_name = get(hs.cell_save_name_box,'string');
%         cell_save = hs.analysis_output.(cell_save_name);
%         cell_save.mini_data{end,2} = hs.thiscell;
%         
%         if hs.ep_ipsc == 1
%             cell_save.epsc_amps{end,2} = hs.thiscell.amp;
%         else
%             cell_save.ipsc_amps{end,2} = hs.thiscell.amp;
%         end
%         hs.analysis_output.(cell_save_name) = cell_save;
%         
        
    end
    ax = gca;
    hs.ax = [ax.XLim ax.YLim];
    plot_mini_analysis()
    
    catch
        disp('add mini button error')
    end

end
    
%%%%%%%%%%%%%%%%%%

% Analyze trace. Extracts passive properties from the seal test in the
% trace and runs the template-based event finding
function mini_analysis(~,~)
    try
    
    if hs.have_analyzed == 0

        if hs.analyze_seal_on == 1
            disp('-------------')
            [Ra, VC_Cp, VC_Rin, Vr] = utils.get_PassProp_VC(hs.data_y_inA, hs.sealteststart, hs.sealtestlength,...
                hs.sealtest_dvolt, hs.samp_rate);        
    
            %save
            hs.savedata = {};
            hs.savedata.Ra = Ra;
            hs.savedata.VC_Cp = VC_Cp;
            hs.savedata.VC_Rin = VC_Rin;
            hs.savedata.Vr = Vr;
        else
            hs.savedata = {};
            hs.savedata.Ra = [];
            hs.savedata.VC_Cp = [];
            hs.savedata.VC_Rin = [];
            hs.savedata.Vr = [];
        end
    end
    
    load_params
    
    rem_seal_but
    
    if hs.remove_60hz_yesno
        disp('Automatically pplying 60Hz filter')
        try

        filt = designfilt('bandstopiir',...
            'FilterOrder',4, ...
            'HalfPowerFrequency1', 58,...
            'HalfPowerFrequency2',62, ...
            'DesignMethod','butter',...
            'SampleRate',hs.samp_rate);

        hs.data_y_inA_filt = filtfilt(filt, hs.data_y_inA);
        trace_toAnalyze = hs.data_y_inA_filt;

%         explore_plot(hs.data_y_inA_filt)
        catch ME
            fprintf(['Filter error: ', '\n'])
            disp(ME)
        end
    else
        trace_toAnalyze = hs.data_y_inA;
    end
    
    try
    hs = rmfield(hs,'full_data');
    hs = rmfield(hs,'cell_data'); 
    end
        
    hs.ax = [];
    hs.have_analyzed = 1;
    hs.loading_text.Visible = 'on';
    drawnow
    
    if hs.mini_analysis_on == 1
        [~, ~, hs.thiscell] = utils.mini_detector_v2(trace_toAnalyze, hs.filters);
    end
    
    hs.loading_text.Visible = 'off';
    drawnow

    %Reset removed minis
    hs.filters.excisecoord = [0,0];
    

    %Temp cutoff testing
%     try
%     bad_f = figure;
%     sort_amps = sort(hs.thiscell.amp);
%     sort_amps = sort_amps(1:9);
%     
%     small_mini_ind = zeros([1 length(sort_amps)]);
%     for mini = 1:length(sort_amps)
%         small_mini_ind(mini) = find(hs.thiscell.amp==sort_amps(mini));
%     end
%     
%     event_start_ind = hs.thiscell.event_start_ind;
%     decay_ind = hs.thiscell.decay_ind;
%     sm_pk_ind = hs.thiscell.sm_pk_ind;
%     event =  hs.thiscell.events.*10^12;
%     for mini = 1:9
%         supersubplot(bad_f, 3,3,mini);
%         ydat = hs.thiscell.events(:,small_mini_ind(mini));
%         plot(ydat.*10^12)
%         hold on
%         plot(event_start_ind(small_mini_ind(mini)), ...
%             event(event_start_ind(small_mini_ind(mini)), small_mini_ind(mini)),'go')
%         plot(sm_pk_ind(small_mini_ind(mini)), ...
%             event(sm_pk_ind(small_mini_ind(mini)),small_mini_ind(mini)),'bo')
%         if isnan(decay_ind(small_mini_ind(mini))) == 0
%             plot(decay_ind(small_mini_ind(mini)),...
%                 event(decay_ind(small_mini_ind(mini)),small_mini_ind(mini)),'ro')
%         end
%     end
%     catch
%         disp('bad mini plot error')
%     end
    
    
    if hs.mini_analysis_on == 1
        plot_mini_analysis()
    end
    
    catch ME
        fprintf(['mini analysis error: ', '\n'])
        disp(ME)
    end
    
end

%%%%%%%%%%%%%%%%%%

% Removes seal from trace (mostly for visualization)
function rem_seal_but(~,~)
    try
    delete(hs.sealtest_line)
    
    %remove the seal test in beginning
    if hs.remove_seal_yesno == 0
        hs.data_y_inA = hs.data_y_inA(hs.sealtestend*hs.samp_rate:end);        
        
        hs.remove_seal_yesno = 1;
    end
    
    if hs.have_analyzed == 0
        explore_plot(hs.data_y_inA)
    end
    
    catch
        disp('remove seal button error')
    end
end

%%%%%%%%%%%%%%%%%%

% Update mini finding global variables from parameter GUI
function load_params(~,~)
    
    try
            
    temp_thresh = get(hs.temp_thresh_box,'string');
    temp_thresh = str2double(temp_thresh);
    
    pre_min_amp = get(hs.pre_min_amp_box,'string');
    pre_min_amp = str2double(pre_min_amp);
    
    post_min_amp = get(hs.post_min_amp_box,'string');
    post_min_amp = str2double(post_min_amp);
    
    sealtest_amp = get(hs.sealtest_amp_box,'string');
    sealtest_amp = str2double(sealtest_amp);
    
    mini_ylims = get(hs.mini_ylims_box,'string');    
    mini_ylims = str2num(mini_ylims);
    
    amp_bias_coeff = get(hs.amp_bias_coeff_box,'string');
    amp_bias_coeff = str2double(amp_bias_coeff);
    
    risetime = get(hs.risetime_box,'string');
    risetime = str2double(risetime);    
    
    %Filter parameters
    hs.filters.DCoffset       = 1;
    hs.filters.Ampthresh = -abs(post_min_amp);
    hs.filters.pre_min_amp = pre_min_amp;
    hs.filters.Templatethresh = temp_thresh;
    hs.filters.excisecoord    = [0,0];
    hs.filters.AmpBiasCoeff = amp_bias_coeff;
    hs.filters.Risetime = risetime;
    
    hs.mini_ylims = mini_ylims;
    
    if hs.fi_mode_on == 0
        hs.sealtest_dvolt = sealtest_amp*10^-3;
    else
        hs.sealtest_dcurr = sealtest_amp*10^-12;
    end
    
    catch
        disp('Load Parameters error')
    end
    
end

%%%%%%%%%%%%%%%%%%

% Saves data analysis results for this trace
function save_this_data_but(~,~)
%     try
        
    if ishandle(hs.save_fig) ~= 1
        make_save_fig
    end

    hs.save_fig.Visible = 'on';
    hs.stored_title.Visible = 'off';
    hs.saved_title.Visible = 'on';
    
    hs.saved_run_num = hs.saved_run_num + 1;
    
% %     Save this raw trace?
%     disp('set to save a raw trace')
%     assignin('base','raw_trace',hs.data_y_inA);
    
    save_param_names = {'Cell','VC_amps','VC_Ra','VC_Rin','VC_Cp','VC_Vr','IC_step_cur',...
        'IC_numhits','IC_Rin','IC_Cp','IC_Vth','VC_Trace_Length(s)'};
    
    if hs.fi_mode_on == 0
        add_to_analysis_output(hs.savedata)
        
        groups = fieldnames(hs.analysis_output);
        for group_num = 1:numel(groups)
            this_groupname = groups(group_num);
            hs.simple_output.(char(this_groupname))(1,:) = save_param_names;       
            cell_fields = fieldnames(hs.analysis_output.(char(this_groupname)));
            hs.simple_output.(char(this_groupname))(2:(numel(cell_fields)+1),1) = cell_fields;
            for cell = 1:length(cell_fields)
                try
                
                if hs.mini_analysis_on == 1
                hs.simple_output.(char(this_groupname)){cell+1,2} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).epsc_amps(:,2);
                end
                hs.simple_output.(char(this_groupname)){cell+1,3} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).Ra(:,2);                
                hs.simple_output.(char(this_groupname)){cell+1,4} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).VC_Rin(:,2);
                hs.simple_output.(char(this_groupname)){cell+1,5} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).VC_Cp(:,2);
                hs.simple_output.(char(this_groupname)){cell+1,6} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).Vr(:,2);   
                hs.simple_output.(char(this_groupname)){cell+1,12} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).VC_Trace_Length(:,2);
                end
            end
        end
        
    else
        add_to_analysis_output(hs.savedata)
        groups = fieldnames(hs.analysis_output);
        for group_num = 1:numel(groups)
            this_groupname = groups(group_num);
            hs.simple_output.(char(this_groupname))(1,:) = save_param_names;       
            cell_fields = fieldnames(hs.analysis_output.(char(this_groupname)));
            hs.simple_output.(char(this_groupname))(2:(numel(cell_fields)+1),1) = cell_fields;
            for cell = 1:length(cell_fields)
                try
                hs.simple_output.(char(this_groupname)){cell+1,7} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).step_cur(:,2);
                hs.simple_output.(char(this_groupname)){cell+1,8} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).numhits(:,2);               
                hs.simple_output.(char(this_groupname)){cell+1,9} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).IC_Rin(:,2);
                hs.simple_output.(char(this_groupname)){cell+1,10} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).IC_Cp(:,2);
                hs.simple_output.(char(this_groupname)){cell+1,11} = ...
                    hs.analysis_output.(char(this_groupname)).(char(cell_fields{cell})).Vth(:,2);                 
                
                end
            end
        end
        
    end
        
    timestamp = clock;
    
    assignin('base', 'Output', hs.analysis_output); 
    assignin('base', 'Simple_Output', hs.simple_output);
    
    analysis_output = hs.analysis_output;
    simple_output = hs.simple_output;
    
    split_path = regexp(hs.zDir,filesep,'split');
    savename = [hs.SaveDir filesep char(split_path(end-1)) '_Save.mat'];
    save(savename, 'analysis_output', 'simple_output')
    clear analysis_output simple_output
    
    hs.saved_filenames{hs.saved_run_num, 1} = char(hs.current_filename);
    set(hs.saved_filenames_box, 'string', flipud(hs.saved_filenames))
    disp('saved')
    
    hs = rmfield(hs,'analysis_output');
    
    hs.have_saved_yesno = 1;
%     catch
%         disp('save data button error')
%     end
end

%%%%%%%%%%%%%%%%%%

% Plot the results of the template based event finding and analysis
function plot_mini_analysis(~,~)
    try
    
    hs = rmfield(hs,'sub_fig');
    hs.sub_fig = subplot('Position',[.07 .1 .6 .8],'visible','on','Parent',hs.fig);
    
    axes(hs.sub_fig)
    time_xaxis = (0:length(hs.thiscell.DATA)-1).*hs.time_scale;
    hs.analyzed_data_y = hs.thiscell.DATA.*hs.amp_scale;
    
    %playing with smoothng out the raw data for easier viewing
    disp('smoothing data shown by 5 (just for viewing)')
    yaxis_for_plot = smooth(hs.analyzed_data_y,5);
    
    plot(hs.sub_fig, time_xaxis, yaxis_for_plot, 'Color', 'black','LineWidth',1.25);
    hold(hs.sub_fig,'on')
    title(hs.current_filename, 'interpreter', 'none')
    set(gca, 'FontSize', 18)
    ylabel( 'Current (pA)')
    xlabel( 'Time (ms)')
    box off
    utils.scrollplot

    r_line = refline(0,-abs(hs.filters.Ampthresh));
    r_line.Color = 'r';
    r_line.LineStyle = '--';
    r_line.LineWidth = 1.0;

    x_placement = nanmean(hs.analyzed_data_y) + 5;
    ylim(hs.sub_fig,hs.mini_ylims)
    hits = hs.thiscell.timeindx .* hs.time_scale;
    excluded = hs.thiscell.excl_minis .*hs.time_scale;
    scatter(hits,repmat(x_placement,1,length(hs.thiscell.timeindx)),'rx')
    scatter(excluded,repmat(x_placement+2,1,length(excluded)),'md') 

    timeindx = hs.thiscell.timeindx;
    amps = hs.thiscell.amp;
    event_start_ind = hs.thiscell.event_start_ind;
    event = hs.thiscell.events .* hs.amp_scale;

    sm_pk_ind = hs.thiscell.sm_pk_ind;
    decay_ind = hs.thiscell.decay_ind;
    
    disp(hs.current_filename)
    disp(['Avg amp = ', num2str(nanmean(amps))])
    disp(['Freq = ', num2str(length(decay_ind)/(time_xaxis(end)/1000))])
    
    start_inds = (event_start_ind+timeindx-1)*hs.time_scale;
    pk_inds = (sm_pk_ind+timeindx-1)*hs.time_scale;
    decay_inds = (decay_ind+timeindx-1)*hs.time_scale;
    plot(start_inds,yaxis_for_plot(round(start_inds*10)),'go')%,'MarkerSize',18,'LineWidth',5)
    plot(pk_inds,yaxis_for_plot(round(pk_inds*10)),'bo')%,'MarkerSize',18,'LineWidth',5)
    plot(decay_inds,yaxis_for_plot(round(decay_inds*10)),'ro')%,'ro','MarkerSize',18,'LineWidth',5)
    
    hold(hs.sub_fig,'off')
    if isempty(hs.ax) == 0
        zoom(gcf, 'reset')
        axis(hs.ax)
    end

    %plots overlay of detected minis
    if isfield(hs,'avg_sub_fig'); hs = rmfield(hs,'avg_sub_fig'); end
    
    hs.avg_sub_fig = subplot('Position',[.715 .1 .1 .8],'visible','on','Parent',hs.fig);
    avg_time_x = (0:(1/hs.samp_rate):(size(hs.thiscell.shifted_events,2)...
        /hs.samp_rate)-(1/hs.samp_rate))*10^3;
    
    plot(hs.avg_sub_fig, avg_time_x, hs.thiscell.shifted_events.*(10^12),'Color', [0 0 1 0.05]);
    hold(hs.avg_sub_fig,'on')
    plot(hs.avg_sub_fig, avg_time_x, nanmean(hs.thiscell.shifted_events.*(10^12),1),'r','LineWidth',3);
    
    hold(hs.avg_sub_fig,'off')
    xlim(hs.avg_sub_fig,[0,20e-4*hs.samp_rate])
    box(hs.avg_sub_fig,'off')
    title(hs.avg_sub_fig,'Mean trace');
    set(hs.avg_sub_fig,'FontSize',12)
   
    catch
        disp('plot mini analysis error (or no minis found)')
    end
    
end

%%%%%%%%%%%%%%%%%%

% Enters mini event finding mode given type of trace data
function mini_mode()
    try
    hs.fi_mode_on = 0;
    hs.excise_but.Visible = 'on';
    hs.analyze_but.Visible = 'on';
    hs.param_fig.Visible = 'on';
    hs.add_mini_but.Visible = 'on';
    hs.rem_mini_but.Visible = 'on';
    hs.save_this_data_but.Visible = 'on';
    hs.rem_seal_but.Visible = 'on';
    hs.ep_ipsc_but.Visible = 'on';
    hs.cell_jump_but.Visible = 'on';    
    hs.cell_jump_box.Visible = 'on';    

    hs.analyze_fi_but.Visible = 'off';
    hs.current_step_int_box.Visible = 'off';
    hs.step_int_label.Visible = 'off';
    
    hs.step_current_label.Visible = 'off';
    hs.step_current_box.Visible = 'off';
    
    set(hs.sealtest_amp_box,'string',num2str(hs.sealtest_dvolt*10^3));
    catch
        disp('mini mode error')
    end
end

%%%%%%%%%%%%%%%%%%

% Simple callback function for Remove 60Hz button
function remove_60hz_but(~,~)
    try
    on_off = hs.remove_60hz_but.Value;
    if on_off
        hs.remove_60hz_yesno = 1;
        hs.remove_60hz_but.BackgroundColor = [0.5 0.5 0.5];
    else
        hs.remove_60hz_yesno = 0;
        hs.remove_60hz_but.BackgroundColor = [0.85 0.85 0.85];
    end
    catch
        disp('60hz removal error')
    end
end
    
%%%%%%%%%%%%%%%%%%

% Simple callback function for epsc_ipsc button (swithces between finding
% epscs and ipscs (assumed to be positive current deflections)
function ep_ipsc_but(~,~)
    
    try
        if hs.ep_ipsc == 1
            hs.ep_ipsc = 2;
            hs.filters.epsc_yes = 0;
        else
            hs.ep_ipsc = 1;
            hs.filters.epsc_yes = 1;
        end

        explore_plot(hs.data_y_inA)
    catch
        disp('ep/ipsc but error')
    end
end

%%%%%%%%%%%%%%%%%%

% Apply a manual change in gain in case there was a discrepancy from what
% amplifier read
function apply_gain_but(~,~)
    
    try
    man_gain = get(hs.apply_gain_box,'string');
    man_gain = str2double(man_gain);
    
    hs.data_y_inA = hs.data_y_inA.*man_gain;
    explore_plot(hs.data_y_inA)
    
    catch
        disp('gain apply error')
    end

end

%%%%%%%%%%%%%%%%%%

% Change y limit in trace window
function apply_ylim_but(~,~)
    try
        mini_ylims = get(hs.mini_ylims_box,'string');    
        hs.mini_ylims = str2num(mini_ylims);
        ylim(hs.sub_fig,hs.mini_ylims)
    catch
        disp('ylim apply error')
    end
end

%%%%%%%%%%%%%%%%%%

% create new average template for mini event matching
function avg_temp_but(~,~)
        
    on_off = hs.avg_temp_but.Value;
    
    try
        if on_off
            
            if hs.have_analyzed ~= 1
                disp('Have not analyzed trace yet -- cannot make avg. template')
                hs.avg_temp_but.Value = 0;
            else

                hs.filters.import_temp_yes = 1;

                disp('Replacing mini average template with current trace...')

                events = hs.thiscell.shift_filt_events.*(10^12);
                ev_amps = hs.thiscell.amp;

                temp_baseline_length = 60;

                decay_thresh_prop = 0.45;
                baseline_end = 25;
                decay_start = 125;

                events_toKeep = [];
                for mini = 1:size(events,1)
                    mini_ev = events(mini,:);
                    mini_ev = mini_ev - nanmedian(mini_ev(1:baseline_end));
                    end_baseline = nanmean(mini_ev(decay_start:end));
                    decay_base_thresh = -ev_amps(mini)*decay_thresh_prop;

                    if end_baseline > decay_base_thresh
                        events_toKeep = padmat(events_toKeep, mini_ev,1);
                    end
                end

                event_avg = nanmean(events_toKeep,1);
                event_med = nanmedian(events_toKeep,1);
                template = nanmean([event_avg; event_med],1);
                template(1:28) = 0;
    %             template = [zeros(1,30) template];
                template = template./-(min(template));

                if length(template) > 200
                    template = template(1:200);
                end

                temp_time = (1/hs.filters.samplerate):(1/hs.filters.samplerate):...
                    length(template)/hs.filters.samplerate;

%                 figure;
%                 plot(temp_time,template,'k','LineWidth',2)
%                 box off
%                 xlabel('Time (s)')

                hs.filters.import_temp = template;
            end

        else
            disp('Changed back to equation-based mini tempalte')
            hs.filters.import_temp_yes = 1;
        end
        
    catch
        disp('average template button error')
    end
end

%%%%%%%%%%%%%%%%%%
% 
% Enters firing rate vs current (FI) mode given type of trace data
function fi_mode()
    hs.fi_mode_on = 1;
    
    hs.excise_but.Visible = 'off';
    hs.analyze_but.Visible = 'off';
    hs.store_for_later_but.Visible = 'off';
    hs.analyze_stored_but.Visible = 'off';
    hs.add_mini_but.Visible = 'off';
    hs.rem_mini_but.Visible = 'off';
    hs.ep_ipsc_but.Visible = 'off';
    hs.cell_jump_but.Visible = 'off';    
    hs.cell_jump_box.Visible = 'off';    

    hs.save_this_data_but.Visible = 'on';
    hs.rem_seal_but.Visible = 'on';
    
    hs.analyze_fi_but.Visible = 'on';
    hs.current_step_int_box.Visible = 'on';
    hs.step_int_label.Visible = 'on';
    
    hs.step_current_label.Visible = 'on';
    hs.step_current_box.Visible = 'on';
    
    set(hs.sealtest_amp_box,'string',num2str(hs.sealtest_dcurr*10^12));
end

%%%%%%%%%%%%%%%%%%
% 
% % Very simple FI analysis function which finds spikes and counts them
% % within a hardcoded window/interval in time
% function analyze_fi(~,~)
%     try
%     hs.have_analyzed = 1;
%     
%     step_int = get(hs.current_step_int_box,'string');
%     step_int = str2num(step_int);
%     step_int(step_int==' ') = '';
%     
%     scaled_x = (0:length(hs.data_y_inA)-1).*hs.time_scale;
%     scaled_y = hs.data_y_inA.*hs.y_scale_factor;
%     
%     int_st = find(scaled_x == step_int(1)*1000)-0.005*hs.samp_rate;
%     int_end = find(scaled_x == step_int(2)*1000)-1;
%     
%     step_data = scaled_y(int_st:int_end);
%     int_median = median(step_data);
%     fi_thresh = 25; %5 mV;
%     
%     past_thresh = ((step_data-int_median) > fi_thresh);
%     
%     hits = diff([0 past_thresh.']);
%     hits(hits<0) = 0;
%     
%     num_hits = sum(hits);
%     disp([num2str(num_hits) ' spikes found'])
%     
%     timeindx = find(hits);
%     
%     peak_amp = NaN([1 length(timeindx)]);
%     AHP_amp = NaN([1 length(timeindx)]);
%     AHP_time = NaN([1 length(timeindx)]);
%     AHP_indx = NaN([1 length(timeindx)]);
%     Width_HP = NaN([1 length(timeindx)]);
%     for hit_x = 1:length(timeindx)
%         try
%         if hit_x ~= length(timeindx)
%             interval = scaled_y(timeindx(hit_x)+int_st:timeindx(hit_x+1)+int_st);
%         else
%             interval = scaled_y(timeindx(hit_x)+int_st:int_end-10);
%         end
% 
%         
%         [peak_amp(hit_x), peak_ind] = max(interval);
% 
%         [ahp_val, ahp_ind] = min(interval);
%         
%         AHP_time(hit_x) = (ahp_ind - peak_ind)*hs.time_scale;
%         AHP_indx(hit_x) = (ahp_ind - peak_ind);
%         
%         int_med = median(interval);
%         AHP_amp(hit_x) = -abs(int_med - ahp_val);
% 
%         relative_amp = max(interval) - int_med;
%         Width_HP(hit_x) = sum(interval(1:ahp_ind)>((relative_amp-5)/2 + int_med))*hs.time_scale;
%         catch
%             disp('spike parameter finding error')
%         end
%     end
%     
%     hit_indx = timeindx;
%     timeindx = timeindx.*hs.time_scale;
%     hold on;
%     try
%     scatter(hs.sub_fig, timeindx+int_st*hs.time_scale, repmat(int_median-5, [1 num_hits]), 'rx')
% %     timef = figure(5); 
% %     plot(timef, timeindx);
%     scatter(hs.sub_fig, AHP_time+timeindx+int_st*hs.time_scale, AHP_amp+int_median, 'bx')
%     
%     catch
%         disp('no hits')
%     end
%     
% %     iclamp_sealtest_current = 25e-12;
% %     sealtest_volt = mean(scaled_y(150*hs.samp_rate/1000:450*hs.samp_rate/1000));
% %     base_volt = mean(scaled_y(550*hs.samp_rate/1000:1050*hs.samp_rate/1000));
% %     Rin = abs((sealtest_volt-base_volt)/1000) / (iclamp_sealtest_current);
%     
%     
%     [IC_Cp, IC_Rin] = get_PassProp_IC(scaled_y.*10^-3, hs.sealteststart, hs.sealtestlength,...
%             hs.sealtest_dcurr, hs.samp_rate);
%        
%         
%     try
%         vth_tresh = 20; %mV/ms
%         fst_ap_indx = round(timeindx(1)*(1/hs.time_scale)+100*hs.time_scale);
%         vth_step_data = step_data(round((fst_ap_indx - 0.005*hs.samp_rate)):fst_ap_indx);
%         inter_time = 1:0.1:length(vth_step_data);
%         interp_v = interp1(1:length(vth_step_data),vth_step_data,inter_time,'pchip');    
%         dv_dt = (interp_v(2:end) - interp_v(1:end-1)).*(10/hs.time_scale);
%         Vth = interp_v(find(dv_dt>vth_tresh,1)-1);
%         disp(['Vth = ',(num2str(Vth))])
% %         figure;plot(interp_v);hold on;plot(dv_dt)
%     catch
%         disp('problem detecting Vth, taking median')
%         Vth = int_median;
%     end
% 
%     step_cur = get(hs.step_current_box,'string');
%     step_cur = str2num(step_cur);
%     step_cur(step_cur==' ') = '';
%     
%     hs.savedata = {};
%     hs.savedata.IC_Rin = IC_Rin;
%     hs.savedata.IC_Cp = IC_Cp;
%     hs.savedata.Vth = Vth;
%     hs.savedata.numhits = num_hits;
%     hs.savedata.timeindx = timeindx;
%     hs.savedata.peak_amp = peak_amp;
%     hs.savedata.AHP_amp = AHP_amp;
%     hs.savedata.AHP_time = AHP_time;
%     hs.savedata.Width_HP = Width_HP;
%     hs.savedata.step_cur = step_cur;
%     
%     catch
%         disp('analyze fi error')
%     end
%     
% end

%%%%%%%%%%%%%%%%%%

% Detects key presses for hotkey implementation
function key_catcher(~,eventdata)
    
    try
    button = eventdata.Character;
    
    if ~exist('xcoord', 'var')
        xcoord = [];
    end
    
    scaled_y = hs.data_y_inA*hs.y_scale_factor;

    if numel(hs.add_mini_pts) < 2
        hs.add_mini_but.Enable = 'off';
    else
        hs.add_mini_but.Enable = 'on';
    end
    if numel(hs.rem_mini_pts) < 2
        hs.rem_mini_but.Enable = 'off';
    else
        hs.rem_mini_but.Enable = 'on';
    end 

    if strcmp(button, 'x') || strcmp(button, 'l')
        [x,y] = ginput;

        x(x<0) = 1;
        x(x>(length(scaled_y)*hs.time_scale)) = ...
            (length(scaled_y)*hs.time_scale);
        decimal_round = round(-log10(hs.time_scale));
        rounded_x = round(x.', decimal_round);
        rounded_x = rounded_x - mod((rounded_x - round(rounded_x)),hs.time_scale);
        xcoord = [xcoord, rounded_x];


        if isempty(xcoord) == 0
        hold on; scatter(x,y);
        if length(xcoord) > 1
            hold on;

            if xcoord(end-1) < xcoord(end)
                first_x = xcoord(end-1);
                sec_x = xcoord(end);
            else
                first_x = xcoord(end);
                sec_x = xcoord(end-1);
            end


            excise_x = first_x:hs.time_scale:sec_x;

            if hs.have_analyzed == 0
                if sec_x > length(scaled_y)*hs.time_scale
                    sec_x = (length(scaled_y)*hs.time_scale);
                    excise_x = first_x:hs.time_scale:sec_x;
                end
                excise_y = scaled_y(round(first_x*1/(hs.time_scale)):...
                    (round(sec_x*1/(hs.time_scale))));

                length_diff = length(excise_x) - length(excise_y);
                if length_diff < 0
                    excise_y = excise_y(1:end+length_diff);
                else
                    excise_x = excise_x(1:end-length_diff);
                end

                hs.excise_pts = [hs.excise_pts; first_x, sec_x];
                plot(excise_x,...
                    excise_y, 'r');
            else
                if sec_x > length(hs.analyzed_data_y)*hs.time_scale
                    sec_x = (length(hs.analyzed_data_y)*hs.time_scale);
                    excise_x = first_x:hs.time_scale:sec_x;
                end

                excise_y = hs.analyzed_data_y(round(first_x*1/(hs.time_scale)):...
                    round(sec_x*1/(hs.time_scale)));

                length_diff = length(excise_x) - length(excise_y);
                if length_diff < 0
                    excise_y = excise_y(1:end+length_diff);
                else
                    excise_x = excise_x(1:end-length_diff);
                end
                %%%%
                assignin('base', 'yaxis_data', hs.analyzed_data_y);
                assignin('base', 'first_x', first_x);
                assignin('base', 'sec_x', sec_x);
                %%%%
                hs.excise_pts = [hs.excise_pts; first_x, sec_x];
                plot(excise_x, excise_y, 'r')
            end

            xcoord = [];
        end
        end

    end

    %%%%%%%
    if strcmp(button, 'p')
        [x,y] = ginput;

        x(x<0) = 1;
        x(x>(length(scaled_y)*hs.time_scale)) = ...
            (length(scaled_y)*hs.time_scale);
        decimal_round = round(-log10(hs.time_scale));
        rounded_x = round(x.', decimal_round);
        rounded_x = rounded_x - mod((rounded_x - round(rounded_x)),hs.time_scale);
        xcoord = [xcoord, rounded_x];


        if isempty(xcoord) == 0
        hold on; scatter(x,y);
        if length(xcoord) > 1
            hold on;

            if xcoord(end-1) < xcoord(end)
                first_x = xcoord(end-1);
                sec_x = xcoord(end);
            else
                first_x = xcoord(end);
                sec_x = xcoord(end-1);
            end

            hs.add_mini_pts = [hs.add_mini_pts; first_x, sec_x];
            add_x = first_x:hs.time_scale:sec_x;

            xcoord = [];

            if hs.have_analyzed == 0
                add_y = scaled_y(round(first_x*1/(hs.time_scale)):...
                    (round(sec_x*1/(hs.time_scale))));

                length_diff = length(add_x) - length(add_y);
                if length_diff < 0
                    add_y = add_y(1:end+length_diff);
                else
                    add_x = add_x(1:end-length_diff);
                end
                plot(add_x,...
                    add_y, 'Color', [.1 .8 .1]);
            else
                add_y = hs.analyzed_data_y(round(first_x*1/(hs.time_scale)):...
                    (round(sec_x*1/(hs.time_scale))));
                length_diff = length(add_x) - length(add_y);
                if length_diff < 0
                    add_y = add_y(1:end+length_diff);
                else
                    add_x = add_x(1:end-length_diff);
                end
                plot(add_x, add_y,'Color', [.1 .8 .1])
            end
        end
        end

    end

    if strcmp(button, 'o')
        [x,y] = ginput;

        x(x<0) = 1;
        x(x>(length(scaled_y)*hs.time_scale)) = ...
            (length(scaled_y)*hs.time_scale);
        decimal_round = round(-log10(hs.time_scale));
        rounded_x = round(x.', decimal_round);
        rounded_x = rounded_x - mod((rounded_x - round(rounded_x)),hs.time_scale);
        xcoord = [xcoord, rounded_x];

        if isempty(xcoord) == 0
        hold on; scatter(x,y);
        if length(xcoord) > 1
            hold on;

            if xcoord(end-1) < xcoord(end)
                first_x = xcoord(end-1);
                sec_x = xcoord(end);
            else
                first_x = xcoord(end);
                sec_x = xcoord(end-1);
            end

            hs.rem_mini_pts = [hs.rem_mini_pts; first_x, sec_x];
            rem_x = first_x:hs.time_scale:sec_x;

            if hs.have_analyzed == 0
                rem_y = scaled_y(round(first_x*1/(hs.time_scale)):...
                    (round(sec_x*1/(hs.time_scale))));

                length_diff = length(rem_x) - length(rem_y);
                if length_diff < 0
                    rem_y = rem_y(1:end+length_diff);
                else
                    rem_x = rem_x(1:end-length_diff);
                end
                plot(rem_x,...
                    rem_y, 'Color', [.1 .8 .1]);
            else
                rem_y = hs.analyzed_data_y(round(first_x*1/(hs.time_scale)):...
                    (round(sec_x*1/(hs.time_scale))));
                length_diff = length(rem_x) - length(rem_y);
                if length_diff < 0
                    rem_y = rem_y(1:end+length_diff);
                else
                    rem_x = rem_x(1:end-length_diff);
                end
                plot(rem_x, rem_y,'Color', [.8 .1 .5])
            end
        end
        end

    end

    %%%%%
    if strcmp(button, '=')
        continue_but();
    end

    %%%%%%%%
    if strcmp(button, char(13))
        if numel(hs.rem_mini_pts) > 1
            rem_mini_but();
        end
        if numel(hs.add_mini_pts) > 1
            add_mini_but()
        end
        if numel(hs.excise_pts) > 1
            excise_but()
        end
    end

    %%%%%
    if strcmp(button, '-')
        back_but();
    end

    if strcmp(button, '\')
        if hs.fi_mode_on == 1
            analyze_fi()
        else
            mini_analysis('plot');
        end
    end

    if strcmp(button, ']')
        if hs.have_analyzed == 1
            save_this_data_but();
        end
    end


    catch ME
        fprintf(['hotkey processor error: ', '\n'])
        disp(ME)
    end
    
    
end

%%%%%%%%%%%%%%%%%%

% Adds new analysis results to an ongiong global save structure
function add_to_analysis_output(savedata)
    
    try
    if hs.have_saved_yesno == 1
        hs.analysis_output = evalin('base','Output');
    end
    
    first_in_group = 0;
    cell_group_name = get(hs.cell_group_box,'string');
    name_exist = sum(ismember(fieldnames(hs.analysis_output),cell_group_name));
    if name_exist == 0
        first_in_group = 1;
        hs.analysis_output.(cell_group_name) = struct;
    end
    
    cell_save_name = get(hs.cell_save_name_box,'string');
    
    if first_in_group == 0
        name_exist = sum(ismember(fieldnames(hs.analysis_output.(cell_group_name)),cell_save_name));
    else
        name_exist = 0;
    end
    
    first_trace = 0;
    if name_exist == 0
        hs.analysis_output.(cell_group_name).(cell_save_name) = {};
        hs.analysis_output.(cell_group_name).(cell_save_name).Rin = {};
        first_trace = 1;
    end
      
    cell_save = hs.analysis_output.(cell_group_name).(cell_save_name);
    fields = fieldnames(cell_save);
    field_sizes = [];
    for field_num = 1:length(fields)
        field_sizes(field_num) = size(cell_save.(char(fields(field_num))),1);
    end
    [num_saved_traces, max_field_ind] = max(field_sizes);

    %just pick one of the fields to get a list of previous trace names
    if first_trace == 0
        fields = fieldnames(cell_save);
        list_of_trace_names = cell_save.(char(fields(max_field_ind)))(:,1);
        already_saved_inds = strcmp(list_of_trace_names,char(hs.current_filename));
    else
        already_saved_inds = NaN;
    end    
    prev_ind = find(already_saved_inds==1);
    if sum(already_saved_inds) > 0
        save_ind = prev_ind;
    else
        save_ind = num_saved_traces + 1;
    end    
    
    hs.trace_save_ind = save_ind;
    
    if hs.fi_mode_on == 0

        list_save_fields = {'Ra','VC_Rin','VC_Cp','Vr','mini_data','epsc_amps','ipsc_amps','VC_Trace_Length'};
        
        for fieldname = list_save_fields
            if ~sum(ismember(fieldnames(cell_save),fieldname))
                cell_save.(char(fieldname)) = {};
            end
        end
        
        cell_save.Ra{save_ind,1} = char(hs.current_filename);
        cell_save.Ra{save_ind,2} = savedata.Ra;
        cell_save.VC_Rin{save_ind,1} = char(hs.current_filename);
        cell_save.VC_Rin{save_ind,2} = savedata.VC_Rin;
        cell_save.VC_Cp{save_ind,1} = char(hs.current_filename);
        cell_save.VC_Cp{save_ind,2} = savedata.VC_Cp;
        cell_save.Vr{save_ind,1} = char(hs.current_filename);
        cell_save.Vr{save_ind,2} = savedata.Vr;
        
        if hs.mini_analysis_on == 1
        cell_save.mini_data{save_ind,1} = char(hs.current_filename);
        cell_save.mini_data{save_ind,2} = hs.thiscell;
        
        hs.thiscell_trace_lengths = length(hs.data_y_inA)/hs.samp_rate;
        cell_save.VC_Trace_Length{save_ind,1} = char(hs.current_filename);
        cell_save.VC_Trace_Length{save_ind,2} = hs.thiscell_trace_lengths;
        
        if hs.ep_ipsc == 1
            cell_save.epsc_amps{save_ind,1} = char(hs.current_filename);
            cell_save.epsc_amps{save_ind,2} = hs.thiscell.amp;
        else
            cell_save.ipsc_amps{save_ind,1} = char(hs.current_filename);
            cell_save.ipsc_amps{save_ind,2} = hs.thiscell.amp;
        end
        end

        hs.analysis_output.(cell_group_name).(cell_save_name) = cell_save;
    end
    
    %%%
    
    if hs.fi_mode_on == 1

        list_save_fields = {'IC_Rin','IC_Cp','Vth','numhits','hit_times',...
            'peak_amp','AHP_amp','AHP_time','Width_HP','step_cur'};
        
        for fieldname = list_save_fields
            if ~sum(ismember(fieldnames(cell_save),fieldname))
                cell_save.(char(fieldname)) = {};
            end
        end
        
        cell_save.IC_Rin{save_ind,1} = hs.current_filename;
        cell_save.IC_Rin{save_ind,2} = savedata.IC_Rin;   
        cell_save.IC_Cp{save_ind,1} = hs.current_filename;
        cell_save.IC_Cp{save_ind,2} = savedata.IC_Cp;  
        cell_save.Vth{save_ind,1} = hs.current_filename;
        cell_save.Vth{save_ind,2} = savedata.Vth;  
        cell_save.numhits{save_ind,1} = hs.current_filename;
        cell_save.numhits{save_ind,2} = savedata.numhits;
        cell_save.hit_times{save_ind,1} = hs.current_filename;
        cell_save.hit_times{save_ind,2} = savedata.timeindx;   
        cell_save.peak_amp{save_ind,1} = hs.current_filename;
        cell_save.peak_amp{save_ind,2} = savedata.peak_amp;      
        cell_save.AHP_amp{save_ind,1} = hs.current_filename;
        cell_save.AHP_amp{save_ind,2} = savedata.AHP_amp;  
        cell_save.AHP_time{save_ind,1} = hs.current_filename;
        cell_save.AHP_time{save_ind,2} = savedata.AHP_time;  
        cell_save.Width_HP{save_ind,1} = hs.current_filename;
        cell_save.Width_HP{save_ind,2} = savedata.Width_HP;  
        cell_save.step_cur{save_ind,1} = hs.current_filename;
        cell_save.step_cur{save_ind,2} = savedata.step_cur; 
        
        
        %update analysis output
        hs.analysis_output.(cell_group_name).(cell_save_name) = cell_save;
    
    end
    catch
        disp('add to analysis output file error')
    end
end

%%%%%%%%%%%%%%%%%%

% GUI object for switching between file types
function file_type(hObject, ~)

    select_ind = hObject.Value;
    
    if select_ind == 1
        hs.mat_or_igor = 'igor';
    else
        hs.mat_or_igor = 'MATLAB';
    end
    
    disp('Filetype changed')
    
end

%%%%%%%%%%%%%%%%%%

% Finds data from a given cell number (only works given data format is what
% the function expects)
function cell_jump_but(~,~)

    try
    jump_num = get(hs.cell_jump_box,'string');
    jump_num = str2double(jump_num);
    
    cell_group = get(hs.cell_group_box,'string');
    cell_save_name = get(hs.cell_save_name_box,'string');
    
    hs.cell_ind = jump_num;
    hs.trace_ind = 0;
    
    try
    hs = rmfield(hs,'full_data');
    hs = rmfield(hs,'cell_data'); 
    end
    
    close(hs.fig);
    hs = rmfield(hs, 'fig');
    
    make_GUI

    hs.panel.Visible = 'off';
    hs.continue_but.Visible = 'on';
    hs.back_but.Visible = 'on';
    hs.excise_but.Visible = 'on';
    hs.analyze_but.Visible = 'on';
    %hs.store_for_later_but.Visible = 'on';
    %hs.analyze_stored_but.Visible = 'on';
    hs.param_fig.Visible = 'on';
    hs.add_mini_but.Visible = 'on';
    hs.rem_mini_but.Visible = 'on';
    hs.save_this_data_but.Visible = 'on';
    hs.rem_seal_but.Visible = 'on';
    hs.cell_save_label.Visible = 'on';
    hs.cell_save_name_box.Visible = 'on';
    hs.ep_ipsc_but.Visible = 'on';
    hs.cell_jump_but.Visible = 'on';    
    
    set(hs.cell_group_box,'string',cell_group)
    set(hs.cell_save_name_box,'string',cell_save_name)
    
    
    continue_but
    
    catch
        disp('cell jump error')
    end


end

%%%%%%%%%%%%%%%%%%

end