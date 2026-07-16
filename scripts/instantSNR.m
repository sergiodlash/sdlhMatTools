%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Instantaneous SNR
%       Compute time-varying SPL (Leq/LAeq) of a signal recording and a
%       noise recording using overlapping frames, and the resulting SNR
%       over time.
%
%   Sergio de las Heras (sergio.delasheras@aalto.fi)
%   2026
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
clear
close all
%%

FS = 48000;

calibrationToneFilename = 'calibrationTone2026.wav';
signalFilename = fullfile('Measurements', 'signal.wav');
noiseFilename  = fullfile('Measurements', 'noise.wav');

start_s = 2;                % Cut the calibration tone start
end_s = start_s + 4;        % Cut the calibration tone end

dB_ref = 94;                % Calibrator ref value dB SPL

do_highPass = true;         % High pass signals
hpCutoff_Hz = 50;           % Highpass cutoff frequency

do_AWeight = true;          % Use A-weighted level (LAeq) instead of Leq

frameLen_s = 0.125;         % Frame length (SLM "Fast" time constant)
frameLen = int(frameLen_s*FS);
hopLen_s   = frameLen_s / 2;% Hop size (50% overlap)
hopLen   = int(hopLen_s *FS);

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
cCalib_dB = dB_ref - calibRec_dBFS;

%% Load signal and noise recordings
[sigAudio, fsSig] = audioread(signalFilename);
[noiseAudio, fsNoise] = audioread(noiseFilename);

assert(fsSig == fs && fsNoise ==  fs && fs == FS, 'Sample rates must match');

if do_highPass
    sigAudio   = highpass(sigAudio, hpCutoff_Hz, fs);
    noiseAudio = highpass(noiseAudio, hpCutoff_Hz, fs);
end

if do_AWeight
    aWeight = weightingFilter('A-weighting', fs);
    sigAudio   = aWeight(sigAudio);
    noiseAudio = aWeight(noiseAudio);
end

%% Compute time-varying level (framed RMS in dB)

nFramesSig = floor((length(sigAudio) - frameLen) / hopLen) + 1;
t_sig     = zeros(nFramesSig, 1);
Lsig_dBFS = zeros(nFramesSig, 1);

for i = 1:nFramesSig
    idxStart = (i-1)*hopLen + 1;
    idxEnd   = idxStart + frameLen - 1;
    frame = sigAudio(idxStart:idxEnd);

    Lsig_dBFS(i) = mag2db(rms(frame));
    t_sig(i) = (idxStart + idxEnd - 1) / 2 / fs;
end

nFramesNoise = floor((length(noiseAudio) - frameLen) / hopLen) + 1;
t_noise     = zeros(nFramesNoise, 1);
Lnoise_dBFS = zeros(nFramesNoise, 1);

for i = 1:nFramesNoise
    idxStart = (i-1)*hopLen + 1;
    idxEnd   = idxStart + frameLen - 1;
    frame = noiseAudio(idxStart:idxEnd);

    Lnoise_dBFS(i) = mag2db(rms(frame));
    t_noise(i) = (idxStart + idxEnd - 1) / 2 / fs;
end

Lsig_dB   = Lsig_dBFS + cCalib_dB;
Lnoise_dB = Lnoise_dBFS + cCalib_dB;

%% Compute SNR over time
% Signal and noise recordings MUST be aligned in time (same start,
% same frame grid), so SNR is computed frame-by-frame. The calibration
% offset cancels out in the subtraction, but is kept above so Lsig_dB and
% Lnoise_dB are in dB SPL.

nFrames = min(nFramesSig, nFramesNoise);
t = t_sig(1:nFrames);
SNR_dB = Lsig_dB(1:nFrames) - Lnoise_dB(1:nFrames);

%% Plot

figure
plot(t_sig, Lsig_dB, 'DisplayName', 'Signal')
hold on
plot(t_noise, Lnoise_dB, 'DisplayName', 'Noise')
xlabel('Time (s)')
ylabel('Level (dB SPL)')
legend
grid on

figure
plot(t, SNR_dB)
xlabel('Time (s)')
ylabel('SNR (dB)')
grid on
