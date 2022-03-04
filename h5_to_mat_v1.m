
% simple script to convert waversurfer h5 ephys files to a .mat structure
% called 'CellStrct' ready for the miniGUI


% choose which chans you recorded from and wish to extract data from
chans_toInclude = [1,2];

% directory of the h5 wavesurfer data in the format such as:
% 'Cell_01_0001_0011'

disp('Select folder that contains h5 ephys files...')
[h5_dir] = uigetdir('','Select folder containing h5 files');

disp('Select folder to save .mat structure in...')
[save_dir] = uigetdir(h5_dir,'Select folder to save .mat structure in...');


% initialize variables
h5_files = dir([h5_dir filesep '*.h5']);

metadata = {};
metadata{1,1} = 'Output Signal';
metadata{2,1} = 'Vclamp In Gain';
metadata{3,1} = 'Sampling Rate';
metadata{4,1} = 'TimeStamp';
metadata{5,1} = 'Data Units';

CellStrct = struct;

disp(['Extracting data from channels: ',num2str(chans_toInclude)])
for file_i = 1:length(h5_files)
    
    h5_file_path = [h5_dir, filesep, h5_files(file_i).name];
    
    fprintf(['Loading File: ', h5_files(file_i).name, '\n'])
    data = ws.loadDataFile(h5_file_path);
    fields = fieldnames(data);
    
    recording_name = char(data.header.DataFileBaseName);
    
    sweepnames = fields(2:end);
        
    for sweep_i = 1:length(sweepnames)
    
        sweep_data = data.(sweepnames{sweep_i}).analogScans; % extracts the data for a sweep
        
        for chan = chans_toInclude
            chan_data = sweep_data(:,chan);
            
            chan_rec_name = [recording_name, '_chan_', num2str(chan)];
                
            sweep_meta = metadata;
            sweep_meta{1,2} = []; % haven't found if output signal is logged in h5 files...'
            sweep_meta{2,2} = 1; % assume gain is 1 for now...
            sweep_meta{3,2} = data.header.AcquisitionSampleRate; % sample rate
            sweep_meta{4,2} = data.header.ClockAtRunStart; % sample rate
            sweep_meta{5,2} = char(data.header.AIChannelUnits(chan)); % units
            
            sweep_num = data.header.NextSweepIndex + sweep_i - 1;
            CellStrct.(chan_rec_name).metadata{sweep_num,1} = [recording_name, '_sweep_', num2str(sweep_num)];
            CellStrct.(chan_rec_name).metadata{sweep_num,2} = sweep_meta;
        
            CellStrct.(chan_rec_name).data{sweep_num,1} = [recording_name, '_sweep_', num2str(sweep_num)];
            CellStrct.(chan_rec_name).data{sweep_num,2} = chan_data;
        end
    
    end
    
end

fprintf(['Enter desired save name for .mat ephys trace structure: \n']);

file_save_name = input('File name: ','s');
full_save_path = [save_dir, filesep, file_save_name '.mat'];
save(full_save_path, 'CellStrct')







