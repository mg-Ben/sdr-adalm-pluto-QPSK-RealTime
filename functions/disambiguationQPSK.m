function [rxstream] = disambiguationQPSK(zI, zQ, disambiguationHeader)
%function [rxstream] = disambiguation(zI, zQ, disambiguationHeader),
%Corrects the ambiguity after the phase synchronization
%Input parameters
% zI, zQ: Output symbols of the derotation module
% synchroAmbiguity: trainig sequence for disambiguation
%
%Output parameters
% rxstream: Corrected bits 
%
disp('Disambiguation')

t=2*disambiguationHeader(1:2:end)-1; %real part of synchroAmbiguity
signalXcorr_tzI= xcorr(t, zI);
[maxAbsXcorr_tzI, indexI] = max( abs( signalXcorr_tzI  ) ); % |<t,ztI>|
Xcorr_tzI = signalXcorr_tzI(indexI);                        %  <t,ztI>

signalXcorr_tzQ= xcorr(t, zQ);
[maxAbsXcorr_tzQ, indexQ] = max( abs( signalXcorr_tzQ  ) ); % |<t,ztQ>|
Xcorr_tzQ = signalXcorr_tzQ(indexQ);                        %  <t,ztQ> 


rxstreamI = zeros(size(zI));
rxstreamQ = zeros(size(zQ));
if ( abs( maxAbsXcorr_tzI ) >= abs( maxAbsXcorr_tzQ ) ), 
  if ( Xcorr_tzI>0 ),
     disp('  Constellation: No change')
      rxstreamI(zI<0)=0;
      rxstreamI(zI>=0)=1;
      rxstreamQ(zQ<0)=0;
      rxstreamQ(zQ>=0)=1;
  else
     disp('  Constellation: +180')
     rxstreamI(zI<0)=1;
     rxstreamI(zI>0)=0;
     rxstreamQ(zQ<0)=1;
     rxstreamQ(zQ>0)=0;
  end;
else % abs( maxXcorr_tzI ) < abs( maxXcorr_tzQ )
  if ( Xcorr_tzQ>=0 )
    disp('  Constellation: +90')
    for i=1:length(zI)
      if     (zI(i)>0 && zQ(i)>0), rxstreamI(i) = 1 ; rxstreamQ(i) = 0;
      elseif (zI(i)>0 && zQ(i)<0), rxstreamI(i) = 0 ; rxstreamQ(i) = 0;
      elseif (zI(i)<0 && zQ(i)>0), rxstreamI(i) = 1 ; rxstreamQ(i) = 1;
      else                         rxstreamI(i) = 0 ; rxstreamQ(i) = 1;
      end; %if
    end; %for
  else
    disp('  Constellation: -90')
    for i=1:length(zI)
      if     (zI(i)>0 && zQ(i)>0), rxstreamI(i) = 0 ; rxstreamQ(i) = 1;
      elseif (zI(i)>0 && zQ(i)<0), rxstreamI(i) = 1 ; rxstreamQ(i) = 1;
      elseif (zI(i)<0 && zQ(i)>0), rxstreamI(i) = 0 ; rxstreamQ(i) = 0;
      else                         rxstreamI(i) = 1 ; rxstreamQ(i) = 0;
      end; %if
    end; %for     
  end; %if (maxXcorr_tzQ2
end; %main if

rxstream = zeros(1, 2*length(zI) );
rxstream(1:2:end) = rxstreamI;
rxstream(2:2:end) = rxstreamQ;