function [x,xd,xdd]=trajectory(t,p)
s=min(1,max(0,(t-p.moveStart)/p.moveDuration));
x=p.x0+(p.x1-p.x0)*(10*s^3-15*s^4+6*s^5);
xd=(p.x1-p.x0)*(30*s^2-60*s^3+30*s^4)/p.moveDuration;
xdd=(p.x1-p.x0)*(60*s-180*s^2+120*s^3)/p.moveDuration^2;
end
