function robust(o)
% robust (reduction)
% by Christian Himpe, 2013 ( http://gramian.de )
% released under BSD 2-Clause License ( http://gramian.de/#license )
%*

if(exist('emgr')~=2) disp('emgr framework is required. Download at http://gramian.de/emgr.m'); return; end

%%%%%%%% Setup %%%%%%%%

 J = 4;
 N = 16;
 O = J;
 R = O;
 T = [0 0.01 1];
 L = (T(3)-T(1))/T(2);
 U = [N*ones(J,1) zeros(J,L-1)];
 X =    ones(N,1);

 A = rand(N,N);
 A(1:N+1:end) = 0;
 B = rand(N,J);
 C = rand(O,N);
 P = -0.55*N*ones(N,1);
 Q = P+5;

 LIN = @(x,u,p) (A+diag(p))*x + B*u;
 OUT = @(x,u,p) C*x;

%%%%%%%% Reduction %%%%%%%%

% FULL
 tic; Y = rk2(LIN,OUT,[J N O],T,X,U,Q); FULL = toc;

% OFFLINE
 tic;
 WC = emgr(LIN,OUT,[J N O],P,T,'c',[0 0 0 0 0 0 0 1 0 0],1,0,0,[ones(J,1);4*ones(N,1)]);
 WO = emgr(LIN,OUT,[J N O],P,T,'o');
 [UU D VV] = squareroot(WC,WO,R);
 x = UU*X;
 lin = @(x,u,p) UU*LIN(VV*x,u,p);
 out = @(x,u,p) OUT(VV*x,u,p);
 OFFLINE = toc

% ONLINE
 tic;
 y = rk2(lin,out,[J R O],T,x,U,Q);
 ONLINE = toc

%%%%%%%% Output %%%%%%%%

% TERMINAL
 ERROR = norm(norm(Y - y)./norm(Y))
 RELER = abs(Y - y)./abs(Y);

% PLOT
 if(nargin<1 || o==0 ), return; end
 l = (1:-0.01:0)'; cmap = [l,l,ones(101,1)];
 figure('PaperSize',[2.4,6.4],'PaperPosition',[0,0,6.4,2.4]);
 imagesc(RELER); caxis([0 max(max(RELER))]); colorbar; colormap(cmap); set(gca,'YTick',1:N);
 if(o==2 && exist('OCTAVE_VERSION')), print -dsvg robust.svg; end

%%%%%%%% Integrator %%%%%%%%

function y = rk2(f,g,q,t,x,u,p)

 T = (t(3)-t(1))/t(2);
 y = zeros(q(3),T);
 h = t(2);

 for A=1:T
  x = x + h*f(x + 0.5*h*f(x,u(:,A),p),u(:,A),p); %Improved Eulers Method
  y(:,A) = g(x,u(:,A),p);
 end

%%%%%%%% Balancer %%%%%%%%

function [X Y Z] = squareroot(WC,WO,R)

 [L D l] = svd(WC); LC = L*diag(sqrt(diag(D)));
 [L D l] = svd(WO); LO = L*diag(sqrt(diag(D)));
 [U Y V] = svd(LO'*LC);
 X = ( LO*U(:,1:R)*diag(1./sqrt(diag(Y(1:R,1:R)))) )';
 Z =   LC*V(:,1:R)*diag(1./sqrt(diag(Y(1:R,1:R))));