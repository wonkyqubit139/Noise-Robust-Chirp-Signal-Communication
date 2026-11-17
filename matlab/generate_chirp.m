% Generate chirp and play it through PC speakers
fs = 4761;
t  = 0 : 1/fs : 0.5;
chirp_signal = chirp(t, 500, 0.5, 1500);

% Play it through your PC speaker
sound(chirp_signal, fs);
