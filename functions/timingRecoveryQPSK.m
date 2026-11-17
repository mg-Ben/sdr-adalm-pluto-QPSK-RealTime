function [zI, zQ]=timingRecoveryQPSK(xI, xQ, M, dseta, Bn),
%function xs=timingRecoveryQPSK(xI, xQ, M, dseta, Bn),
%Timing synchronization for the ideal system
%
%Input parameters
% x: Matching filter output
% M: Oversampling factor or samples per Symbol
% dseta: PLL parameter. Damping factor 
% Bn: PLL parameter. Noise BandWidth
%
%Output parameters
% zI, zQ: Decimated output samples (one per symbol)
%

x = sqrt( xI.^2 + xQ.^2 );  

%PLL constants
fs = 500; T=1/fs;  %sampling frequency
%Bn = 25;            %noise Bandwidth(Hz)
kp = 1;            %phase gain
k0 = 1;            %VCO gain
%dseta = 1;         %damping factor

%Computing the P-I loop-filter constants; k1 and k2
wn=Bn*T/( dseta+1/(4*dseta) );       %natural frequency 
k1 = 4*dseta*wn/(1+2*dseta*wn+wn^2); %k1
k2 = 4*wn^2/(1+2*dseta*wn+wn^2);     %k2

% clock recovery algorithm initializations
lside = 50;            % initialization for
tnow  = lside*M+1;     % intersinc

i=0;   %loop index
tau=0; 
tauplot=zeros(size(x)); tauplot(1)=tau; %for plotting
xs=zeros(size(x)); 

delta=0.1;     % time for derivative
accError=0;    % PLL
while tnow<length(x)-lside,         % run iteration
  i=i+1;
  %TED
  xs(i)    = interpsinc(x,tnow+tau,lside);       % interp value at tnow+tau
  zI(i)    = interpsinc(xI,tnow+tau,lside);
  zQ(i)    = interpsinc(xQ,tnow+tau,lside);
  x_deltap = interpsinc(x,tnow+tau+delta, lside);% value to right
  x_deltam = interpsinc(x,tnow+tau-delta,lside); % value to left
  dx       = x_deltap-x_deltam;                  % numerical derivative
   
  error = dx*xs(i);                 %PLL alg. update:OP 
  
  %PLL 
  accError = accError + error;
  tau = tau + k1*error + k2*accError;
  
  tnow=tnow+M; 
  tauplot(i)=tau;      % save for plotting
end

% plot results
figure(1),
subplot(2,2,1), plot(xI, xQ,'.')        % plot constellation diagram
title('Input constellation diagram'); axis square; grid
subplot(2,2,2), plot(zI, zQ,'.')        % plot constellation diagram
title('Output constellation diagram'); axis square; grid
subplot(2,1,2), plot(tauplot(1:i-2))        % plot trajectory of tau
title('Timing recovery')
ylabel('tau estimates'), xlabel('iterations')

