%% FIR low-pass filter for removing background noise from audio
%
% Namal University, Mianwali - Digital Signal Processing lab project
% Author: Muhammad Usman Shah (NUM-BSEE-2022-28)
%
% What this script does
%   1. Reads an audio file.
%   2. Adds white Gaussian noise to simulate a noisy environment.
%   3. Designs an FIR low-pass filter with fir1 and applies it to the noisy audio.
%   4. Plots the original, noisy and filtered signals in time and frequency.
%   5. Saves the noisy and filtered audio as .wav files and (optionally) plays them.
%
% Requires MATLAB R2016b or newer (local functions in scripts) and the
% Signal Processing Toolbox (for fir1).

clc;
clear;
close all;

%% Settings - change these to reproduce the experiments in the report
audioFile   = fullfile('..', 'audio', 'Fight.mp3');   % run from the src folder
noiseLevel  = 0.05;          % standard deviation of the added noise
filterOrder = 10;            % number of FIR taps minus one
cutoffHz    = 3000;          % low-pass cutoff frequency in Hz
playSounds  = true;          % set to false to skip playback
outputDir   = fullfile('..', 'output');   % noisy/filtered wav files go here

rng(42);                     % fixed seed so the noise is the same every run

%% 1. Load the audio
[cleanAudio, fs] = audioread(audioFile);

if cutoffHz >= fs / 2
    error('Cutoff (%d Hz) must be below the Nyquist frequency (%g Hz).', ...
          cutoffHz, fs / 2);
end

%% 2. Add white Gaussian noise
noisyAudio = cleanAudio + noiseLevel * randn(size(cleanAudio));

%% 3. Design the FIR low-pass filter and apply it
% fir1 expects the cutoff as a fraction of the Nyquist frequency (fs/2).
normalizedCutoff = cutoffHz / (fs / 2);
firCoeffs = fir1(filterOrder, normalizedCutoff);

filteredAudio = filter(firCoeffs, 1, noisyAudio);

%% 4. How much did the filter help?
% An FIR filter of order N delays the output by N/2 samples, so shift the
% filtered signal back before comparing it with the clean original.
delay = floor(filterOrder / 2);
snrBefore = snrInDb(cleanAudio, noisyAudio);
snrAfter  = snrInDb(cleanAudio(1:end-delay, :), filteredAudio(1+delay:end, :));

fprintf('Sampling rate : %d Hz\n', fs);
fprintf('Noise level   : %.2f\n', noiseLevel);
fprintf('Filter        : order %d, cutoff %d Hz\n', filterOrder, cutoffHz);
fprintf('SNR noisy     : %.2f dB\n', snrBefore);
fprintf('SNR filtered  : %.2f dB\n', snrAfter);

%% 5. Time-domain plots
t = (0:size(noisyAudio, 1) - 1) / fs;

figure('Name', 'Time domain');

subplot(3, 1, 1);
plot(t, cleanAudio);
title('Original Signal');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(3, 1, 2);
plot(t, noisyAudio);
title('Original Signal with Noise');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(3, 1, 3);
plot(t, filteredAudio);
title('Filtered Audio');
xlabel('Time (s)');
ylabel('Amplitude');

%% 6. Frequency-domain plots
numSamples = size(noisyAudio, 1);
freqAxis   = fs * (0:numSamples - 1) / numSamples;
maxPlotHz  = min(8000, fs / 2);

figure('Name', 'Frequency domain');

subplot(3, 1, 1);
plot(freqAxis, abs(fft(cleanAudio)));
xlim([0 maxPlotHz]);
title('Frequency Response of Original Signal');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

subplot(3, 1, 2);
plot(freqAxis, abs(fft(noisyAudio)));
xlim([0 maxPlotHz]);
title('Frequency Response of Original Signal with Noise');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

subplot(3, 1, 3);
plot(freqAxis, abs(fft(filteredAudio)));
xlim([0 maxPlotHz]);
title('Frequency Response of Filtered Audio');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

%% 7. Save the results as audio files
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% audiowrite clips anything outside [-1, 1], so scale down if needed.
audiowrite(fullfile(outputDir, 'noisy.wav'), ...
           noisyAudio / max(1, max(abs(noisyAudio(:)))), fs);
audiowrite(fullfile(outputDir, 'filtered.wav'), ...
           filteredAudio / max(1, max(abs(filteredAudio(:)))), fs);

%% 8. Listen: original, then noisy, then filtered
if playSounds
    clips = {cleanAudio, noisyAudio, filteredAudio};
    for k = 1:numel(clips)
        sound(clips{k}, fs);
        pause(size(clips{k}, 1) / fs + 1);
    end
end

%% Local functions
function ratioDb = snrInDb(reference, signal)
% Signal-to-noise ratio of "signal" measured against a clean reference.
    residual = signal - reference;
    ratioDb = 10 * log10(sum(reference(:) .^ 2) / sum(residual(:) .^ 2));
end
