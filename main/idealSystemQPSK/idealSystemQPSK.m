%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Design of Communication Systems and Equipment
% file: BasicQPSKwithAllSynchronizations.m
%
% System with QPSK modulation and that includes the following files: 
%   - PLL timing synchronization: timingRecoveryQPSK.m
%   - PLL derotation and slicer: derotationQPSK.m
%   - Disambiguation: disambiguationQPSK.m
%   - input data. txStream.mat
%   - msg2text. ascii code to text 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath(genpath("functions"));
clear; clf; clc;

%% Parameters
%frame
frameHeader     = [1 0 1 0 0 1 1 1 0 1];    % frame Sychronization (included in txStream file)
%synchroHeader= zeros(1,500);               % Necessary for time synchronization
%synchroHeader(1:2:end)=ones(1,250);        % BPSK 
% synchroHeader=repmat([1 1 0 0 1 0 0 1], 1, 65); %QPSK

synchroHeader_I_zeroMean = repmat([1 1 1 1 1 -1], 1, 17);
synchroHeader_Q_zeroMean = [repmat([1 1 1 -1], 1, 24), 1, 1, 1, 1, 1, 1];
synchroHeader_zeroMean = zeros(1, length(synchroHeader_I_zeroMean)+length(synchroHeader_Q_zeroMean));
synchroHeader_zeroMean(1:2:end) = synchroHeader_I_zeroMean;
synchroHeader_zeroMean(2:2:end) = synchroHeader_Q_zeroMean;
synchroHeader_zeroMean = (synchroHeader_zeroMean+1)/2;
synchroHeader = synchroHeader_zeroMean;

rng(0); disambiguationHeader = round(rand(1,50));  % Remove the synchronization phase ambiguity

% Symbols
M = 9;              % Samples per symbol=Oversamplig factor

% Modulation
fs=10e5; Ts =1/fs;            % Sampling frequency
fc=2.4e9;                       % Carrier frequency
phi=pi/8; deltafc=10;           % Carrier phase & frequency error
Tt=20;      % Transmission duration (s)

% Channel
SNR=30;               %dB

%% ADALM-PLUTO initialization
% tx=sdrtx('Pluto');
% tx.CenterFrequency = fc;
% tx.Gain = -10;
% tx.BasebandSampleRate = fs;
% 
% rx=sdrrx('Pluto');
% rx.CenterFrequency = fc;
% rx.BasebandSampleRate = fs;
% rx.GainSource = 'Manual';
% rx.Gain = 0;

%% Rx settings
Ny=20000;

%% Baseband Tx - mapping + shaping filter
% frame
load("others/resources/txStream.mat")           % Loading the bits
txStream = [synchroHeader'; disambiguationHeader'; txStream; zeros(100,1)]; %zeros are added                                                    %compensate the                                                      %filters

% QPSK mapping
%m = 2*txStream - 1;
mI = 2*txStream(1:2:end)-1;
mQ = 2*txStream(2:2:end)-1;

NSymbols = length(mI);   %Number of Symbols

%Shaping filtering - oversampling + pulse shaping
% Oversampling by M
meI=zeros(1, M*NSymbols);      
meI(1:M:end)= mI;        % Oversampling the message vector by M
meQ=zeros(1, M*NSymbols);      
meQ(1:M:end)= mQ;        % Oversampling the message vector by M

% Pulse shaping
ps=hamming(M);                     % hamming pulse of width M
msI=filter(ps,1,meI);              % convolve pulse shape with data
msQ=filter(ps,1,meQ);

% Transmit signal over-the-air:
x = msI' + 1j*msQ';
if length(x) < 5000
    x = [x; zeros(5000-length(x),1)];
end

% transmitRepeat(tx,x);
% pause(Tt)

% Receive signal:
y=zeros(Ny,1);
% [y,valid,overflow]=rx();

% release(tx);
% release(rx);

%% Algorithm to detect the beginning of xfI and xfQ on received buffer y:
% We compute the cross-correlation with synchroHeader:
% To do so, we can take the synchroHeader part of transmitted signal as:
processed_synchroHeader_msI = msI(1:(length(synchroHeader)/2) * M)';
processed_synchroHeader_msQ = msQ(1:(length(synchroHeader)/2) * M)';
processed_synchroHeader = processed_synchroHeader_msI + 1j*processed_synchroHeader_msQ;
% Cross correlation with y:
[correlation, lags] = xcorr(y, processed_synchroHeader);
[max_correlation, max_index] = max(abs(correlation));
starting_index = lags(max_index)+1;
% We would take y from that index:
transmitted_size = length(msI); % Here, we eliminate the added zeros that we added on tx side to fill 5000 samples
y_sample = y(starting_index:starting_index+transmitted_size-1);
r2I = real(y_sample(starting_index:starting_index+transmitted_size-1));
r2Q = imag(y_sample(starting_index:starting_index+transmitted_size-1));
order=30; fbe = [0 0.25 0.3 1]; damps=[1 1 0 0]; b = firpm(order,fbe,damps); xfI = filter(b,1,r2I);
xfI = filter(b,1,r2I);
xfQ = filter(b,1,r2Q);
rms_value = rms(xfI + 1j*xfQ);
xfI = xfI/rms_value;
xfQ = xfQ/rms_value;

%% Comment out the next part of code:
% xfI = msI;
% xfQ = msQ;
% 
% 
% %% Receiver - Matching filtering + Timing Recovery + Phase recovery and slicer +
% %             + Phase Ambiguity Correction
% %matching filter
% xI=filter(ps,1,xfI); 
% xQ=filter(ps,1,xfQ); 
% 
% % timing recovery
% dseta = 1; Bn=25;
% [ztI, ztQ] = timingRecoveryQPSK(xI, xQ, M,dseta,Bn);
% % ztI = xI(30:M:end);   %counting the delays
% % ztQ = xQ(30:M:end);
% 
% % non-definitive code
% % zI  = zeros( size(ztI) ); zI(ztI>0) = 1;
% % zQ  = zeros( size(ztQ) ); zQ(ztQ>0) = 1;
% % rxStream=zeros( 1,2*length(zI) ); 
% % rxStream(1:2:end) = zI;
% % rxStream(2:2:end) = zQ;
% 
% % Phase recovery and slicer
% [zI, zQ] = derotationQPSK(ztI, ztQ);
% 
% % Phase ambiguity correction
% rxStream = disambiguationQPSK(zI, zQ, disambiguationHeader);
% 
% 
% %% Unframe and Message Visualization - frame synchronization + Presentation Layer
% disp('Frame Synchronization')
% rh = xcorr(2*rxStream-1, 2*frameHeader-1); Rrh = rh( (length(rh)+1)/2:end );
% [maxim, ind] = max(Rrh); headStart = ind(1); 
% if (maxim == 10) 
%   disp('  Sucessful Frame Header Detection');
% 
%   % Presentation layer
%   lengthMessagebin = num2str( rxStream(headStart+10:headStart+10+(24-1)) );
%   lengthMessage    = bin2dec(lengthMessagebin(:)');
%   %lengthMessage=44;
%   disp(['  Message length: ' num2str(lengthMessage)] );
% 
%   rxMsg = rxStream(headStart+10+24:headStart+10+24+8*(lengthMessage)-1 );
%   disp(['  Message: ' msg2text(rxMsg') ]); %ascii to text
% else
%    disp('  ERROR: Frame Header NOT Detected');  
% end;
