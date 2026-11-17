function [zI, zQ] = derotationQPSK(ztI, ztQ),
%function [zI, zQ] = derotationQPSK(ztI, ZtQ),
%QPSK baseband phase derotation
%
%Input parameters
% ztI, ztQ: unsynchronized phase symbols
%
%Output parameters
% zI, zQ: synchronized phase  symbols
%

%PLL constants
fs = 500; T=1/fs;  %sampling frequency
Bn = 25;            %noise Bandwidth(Hz)
kp = 1;            %phase gain
k0 = 1;            %VCO gain
dseta = 1;         %damping factor

%Computing the P-I loop-filter constants; k1 and k2
wn=Bn*T/( dseta+1/(4*dseta) );       %natural frequency 
k1 = 4*dseta*wn/(1+2*dseta*wn+wn^2); %k1
k2 = 4*wn^2/(1+2*dseta*wn+wn^2);     %k2

zt= ztI + 1j*ztQ;
zs=zeros(size(zt)); zs(1)=zt(1);
theta=0; thetaplot = zeros(size(zt));
accError =0; M1=0;M2=0;
for i=1:length(zt),
  %slicer
  zsI(i)=real(zs(i)); zsQ(i)=imag(zs(i));    
  if     (zsI(i)>0 && zsQ(i)>0), z(i) =  1 + 1j;
  elseif (zsI(i)>0 && zsQ(i)<0), z(i) =  1 - 1j;
  elseif (zsI(i)<0 && zsQ(i)>0), z(i) = -1 + 1j;
  else                           z(i) = -1 - 1j;
  end;
 
  aux = zs(i)*z(i)'; 
  error = atan2(imag(aux), real(aux) );    
    
  %PLL loop filter
  accError = error + accError;
  theta = theta + k1*error + k2*accError; %theta estimation
  
  zs(i+1) = zt(i).*exp(-1j*theta); %derotation correction
  
  thetaplot(i)=theta;
end;
zI = real(z); 
zQ = imag(z); 


% plot results
figure(2),
subplot(221); plot(ztI, ztQ,'b.')    % plot input constellation diagram
title('Input constellation diagram'); axis square; grid
subplot(222); plot(real(zs), imag(zs),'b.')     % plot output constellation diagram
title('Output constellation diagram'); grid; axis square; 
subplot(212); plot(thetaplot)
title('Derotation & Slicer'); ylabel('theta correction')



