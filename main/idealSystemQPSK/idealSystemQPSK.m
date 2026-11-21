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
tx=sdrtx('Pluto');
tx.CenterFrequency = fc;
tx.Gain = -10;
tx.BasebandSampleRate = fs;

rx=sdrrx('Pluto');
rx.CenterFrequency = fc;
rx.BasebandSampleRate = fs;
rx.GainSource = 'Manual';
rx.Gain = 0;

%% Rx settings
Ny=20000;

%% Baseband Tx - mapping + shaping filter
% frame
load("others/resources/txStream.mat")           % Loading the bits
txStream = [synchroHeader'; disambiguationHeader'; txStream; zeros(100,1)]; %zeros are added                                                    %compensate the                                                      %filters

% QPSK mapping
%m = 2*txStream - 1;
mI = 2*txStream(1:2:end)-1;
% Choose synchroHeader so that mean is zero:
% We can calculate the sum of [disambiguationHeader+txStream+zeros] as:
start_index = (length([1 1 0 0 1 0 0 1])/2)*65+1;
mI_sum_without_syncHeader = sum(mI(start_index:end));
% The sum is -68. Therefore, we need to define a
% header for mI such that that header sum is +68:
% The synchronizationHeader of mI has length = 4, so we must decide a
% 4-length vector with values 1 or -1 such that that vector repeated 65
% times has a sum equal to +68. Consequently: the header sum multiplied by
% 65 must be equal to 68. Then, the header sum must be 68/65 = 1.0462
% The closest solution is a vector with sum = 1. For example: [1], [-1, 1,
% 1] (in any order), [-1, -1, 1, 1, 1] (in any order)...
mQ = 2*txStream(2:2:end)-1;
% We do the same as mI for mQ:
mQ_sum_without_syncHeader = sum(mQ(start_index:end));
% The sum for the current values is -54.
% We need a header such that the sum *65 is equal to +54.
% The sum of a single header can be 0.8308 (1 is the closest value)

% However, if we are able to modify the number of repetitions of
% synchroHeader (65), we choose the header defined for exactly zero-mean (see above on input variables)

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

transmitRepeat(tx,x);
pause(Tt)

% Receive signal:
y=zeros(Ny,1);
[y,valid,overflow]=rx();

release(tx);
release(rx);

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
