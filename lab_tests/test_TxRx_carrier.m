fs=10e5;
fc=2.4e9;

tx=sdrtx('Pluto');
tx.CenterFrequency = fc;
tx.Gain = -10;
tx.BasebandSampleRate = fs;

Nf=40;          % Number of receive buffers
Nx=100;         % Period of transmit sinusoid (samples)

N=5000;
x=exp(1i*2*pi/Nx*(1:N)');
x=complex(x);

transmitRepeat(tx,x);

pause(5);               % Let the transmitter stabilize

rx=sdrrx('Pluto');
rx.CenterFrequency = fc;
rx.BasebandSampleRate = fs;
rx.GainSource = 'Manual';
rx.Gain = 0;

Ny=20000;
y=zeros(Ny*Nf,1);

for ic=1:Nf
    [y(Ny*(ic-1)+(1:Ny)),valid,overflow]=rx();
    if overflow; disp(ic); end
end

release(rx);
release(tx);

figure(1);
subplot (121); plot(y); grid on; axis('square'); axis('equal');
xlabel('in-phase'); ylabel('quadrature');
subplot(222); plot(real(y)); title('in-phase');
subplot(224); plot(imag(y)); title('quadrature');



