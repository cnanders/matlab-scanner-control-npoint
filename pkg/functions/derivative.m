% 1st order derivative approximation

% Input row vector or matrix.  If input is a matrix, it takes derivatives
% along the rows so dx shoud be the

% Update 5/11/2007. Going to try and implement a centered divided
% difference derivative.


function out = derivative(varargin)

% varargin should be a minimum of two things: 

% 1) Matrix or vector you want to differentiate
% 2) Sample spacing in the direciton of the derivative
% 3) If you input a matrix you can indicate whether or not to do rows or
% cols - it will default to rows if you do not specify.

% Example call:

% You desire the x derivative of a matrix; take the derivative along the cols 
% because the way I define my coordinates x changes in the columns of a matrix.

% A = some matrix
% dMatrix_dx = derivative(M,dx,'cols')

switch nargin   
    case 1  
        error('minimum of two inputs required')
    case 2
        f = varargin{1};
        dx = varargin{2};
        dim = 'rows';
        
        [Nx,Ny] = size(f);
        if Nx ~=1 & Ny~=1
            disp('Derivative along rows of matrix (default setting)')
        end
        
    case 3
        f = varargin{1};
        dx = varargin{2};
        dim = varargin{3};
        
    otherwise
        error('unexpected inputs')
end


[Nrows,Ncols] = size(f);

switch dim
    case 'rows'
        
		for m = 1:Nrows
            for k = 1:Ncols
                if k == 1
                    out(m,k) = (f(m,k+1) - f(m,k))/dx;
                    % forward difference derivative along row;
                end
                if k < Ncols & k > 1
                    out(m,k) = (f(m,k+1) - f(m,k-1))/dx/2;
                    % centered divided difference derivative along row;
                end
                if k == Ncols
                    out(m,k) = out(m,k-1);
                end
            end
		end
        
    case 'cols'
        
        for k = 1:Ncols 
            for m = 1:Nrows
                if m == 1
                    out(m,k) = (f(m+1,k) - f(m,k))/dx;
                    % forward difference derivative down column;
                end
                if m < Nrows & m > 1
                    out(m,k) = (f(m+1,k) - f(m-1,k))/dx/2;
                    % centered divided difference derivative down column;
                end
                if m == Nrows
                    out(m,k) = out(m-1,k);
                end
            end
		end
        
end
        