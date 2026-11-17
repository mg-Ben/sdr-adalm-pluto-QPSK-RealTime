fs=6e5;
fc=2.4e9;

% Open transmitter and configure it

tx=sdrtx('Pluto');

% Set transmitter parameters:
% Carrier frequency
% Sampling rate
% Transmitter gain. -10 is adequate for connecting the spectrum analyser

tx.CenterFrequency = fc;
tx.BasebandSampleRate = fs;
tx.Gain = -10;

N = 5000;           % Length of transmission buffer
x = ones(N,1);      % Signal to be transmitted
Tt = 20;            % Transmission duration (s)

x=complex(x);       % PLUTO requires complex (I/Q) signals

transmitRepeat(tx,x);  % Transmission buffer is repeated until release

pause(Tt)           % Release after Tt seconds
release(tx);
