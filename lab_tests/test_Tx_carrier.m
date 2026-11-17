%
% Signal menu:
% 0: Carrier only
% 1: Cosine with period Nx samples
% 2: Two complex sinusoids with period Nx samples and different amplitudes
% 3: Pseudo-random QPSK with length N samples, 10 samples per symbol
%    and Hanning pulse shaping.
%

Sselect=3;  % Signal type selection
Tt=20;      % Transmission duration (s)

fs=10e5;
fc=2.4e9;

tx=sdrtx('Pluto');
tx.CenterFrequency = fc;
tx.Gain = -10;
tx.BasebandSampleRate = fs;

% Try to reduce the frequency offset as
% measured by the analyser. Units are ppm ref to carrier

%tx.FrequencyCorrection = 4.1892;   

N=5000; % Transmit buffer length
switch Sselect
    case 0
        x=ones(N,1);
    case 1
        Nx=10;
        x=0.5*(exp(1i*2*pi/Nx*(1:N)')+exp(-1i*2*pi/Nx*(1:N)'));
    case 2
        Nx=10;
        x=0.5*(exp(1i*2*pi/Nx*(1:N)')+exp(-1i*2*pi/Nx*(1:N)')/sqrt(10));
    case 3
        x=base_QPSK(N,10,0).';
end
x=complex(x);
transmitRepeat(tx,x);
pause(Tt)
release(tx);

