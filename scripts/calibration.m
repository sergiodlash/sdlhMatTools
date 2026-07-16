%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Calibration
%       Get calibration factors from measurements and a calibration tone.
%       Compute SPL level of recorded signals in Leq and Laq
%
%   Sergio de las Heras (sergio.delasheras@aalto.fi)
%   2026
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear
close all
%%

calibrationToneFilename = 'calibrationTone2026.wav';

start_s = 2;                % Cut the calibration tone start
end_s = start_s + 4;        % Cut the calibration tone end

dB_ref = 94;                % Calibrator ref value dB SPL

do_highPass = true;         % High pass signals
hpCutoff_Hz = 50;           % Highpass cutoff frequency

do_LAeq = true;             % Also compute A-weighted LAeq


%% Compute Calibration
[calibTone, fs] = audioread(calibrationToneFilename);

if do_highPass
    calibTone = highpass(calibTone, hpCutoff_Hz, fs);
end

% Cut
idx_start = round(fs * start_s) + 1;
idx_end   = round(fs * end_s);
calibTone = calibTone(idx_start:idx_end);

% Calibration mic correction
calibRec_dBFS = mag2db(rms(calibTone));

cCalib_dB = db_ref - calibRec_dBFS;
cCalib = db2mag(cCalib_dB);

% cCalib is the calibration factor (gain) that relates dBFS to dBSPL.
% If you want to get dBSPL from a measurement, you have to multiply the
% recorded signal by cCalib and do mag2db.

%% Compute DB SPL of recorded signals
% Load recorded signals, compute SPL

listing = dir(fullfile("./Measurements/", "*.wav"));
LS_rec_filenames = {listing(~[listing.isdir] ).name};

%% LS calibration
ls_dBs = cell(length(LS_rec_filenames), 1);
ls_dBAs = cell(length(LS_rec_filenames), 1);

for i = 1:length(LS_rec_filenames)
    ls_audio = audioread(fullfile('./Measurements/', LS_rec_filenames{i}));

    % Cut
    ls_audio = ls_audio(4*fs:8*fs);
    if do_highPass
        ls_audio = highpass(ls_audio, hpCutoff_Hz, fs);
    end

    % Compute SPL 
    L_dB = mag2db(rms(cCalib * ls_audio));
    ls_dBs{i} = L_dB;

    if do_LAeq
        AWeighting = weightingFilter('A-weighting',fs);
        ls_audio_A = AWeighting(ls_audio);
        L_dBA = mag2db(rms(cCalib * ls_audio_A));
        ls_dBAs{i} = L_dBA;
    end

end


