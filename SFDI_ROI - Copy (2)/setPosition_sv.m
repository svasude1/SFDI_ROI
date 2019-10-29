function setPosition_sv(obj,pos)
%setPosition  Set polygon to new position.
%
%   setPosition(h,pos) sets the polygon h to a new position.
%   The new position, pos, has the form [X1 Y1;...;XN YN].

invalidPosition = ~ismatrix(pos) || size(pos,2) ~=2 || ~isnumeric(pos);
if invalidPosition
    error(message('images:impoly:invalidPosition'))
end

obj.api.setPosition_sv(pos);

end