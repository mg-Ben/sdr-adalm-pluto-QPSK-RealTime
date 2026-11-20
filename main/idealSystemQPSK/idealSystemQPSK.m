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
synchroHeader=repmat([1 1 0 0 1 0 0 1], 1, 65); %QPSK
rng(0); disambiguationHeader = round(rand(1,50));  % Remove the synchronization phase ambiguity

% Symbols
M = 9;              % Samples per symbol=Oversamplig factor

% Modulation
fs=10000; Ts =1/fs;            % Sampling frequency
fc=2000;                       % Carrier frequency
phi=pi/8; deltafc=10;           % Carrier phase & frequency error

% Channel
SNR=30;               %dB

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

xfI = msI;
xfQ = msQ;


%% Receiver - Matching filtering + Timing Recovery + Phase recovery and slicer +
%             + Phase Ambiguity Correction
%matching filter
xI=filter(ps,1,xfI); 
xQ=filter(ps,1,xfQ); 

% timing recovery
dseta = 1; Bn=25;
[ztI, ztQ] = timingRecoveryQPSK(xI, xQ, M,dseta,Bn);
% ztI = xI(30:M:end);   %counting the delays
% ztQ = xQ(30:M:end);

% non-definitive code
% zI  = zeros( size(ztI) ); zI(ztI>0) = 1;
% zQ  = zeros( size(ztQ) ); zQ(ztQ>0) = 1;
% rxStream=zeros( 1,2*length(zI) ); 
% rxStream(1:2:end) = zI;
% rxStream(2:2:end) = zQ;

% Phase recovery and slicer
[zI, zQ] = derotationQPSK(ztI, ztQ);

% Phase ambiguity correction
rxStream = disambiguationQPSK(zI, zQ, disambiguationHeader);


%% Unframe and Message Visualization - frame synchronization + Presentation Layer
disp('Frame Synchronization')
rh = xcorr(2*rxStream-1, 2*frameHeader-1); Rrh = rh( (length(rh)+1)/2:end );
[maxim, ind] = max(Rrh); headStart = ind(1); 
if (maxim == 10) 
  disp('  Sucessful Frame Header Detection');
  
  % Presentation layer
  lengthMessagebin = num2str( rxStream(headStart+10:headStart+10+(24-1)) );
  lengthMessage    = bin2dec(lengthMessagebin(:)');
  %lengthMessage=44;
  disp(['  Message length: ' num2str(lengthMessage)] );

  rxMsg = rxStream(headStart+10+24:headStart+10+24+8*(lengthMessage)-1 );
  disp(['  Message: ' msg2text(rxMsg') ]); %ascii to text
else
   disp('  ERROR: Frame Header NOT Detected');  
end;
