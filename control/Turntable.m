classdef Turntable
    % TURNTABLE Class for the control of the Outline ET250-3D turntable
    % 
    %   Turntable Methods:
    %       Turntable               - Construct a turntable object
    %       resetPosition           - Move turntable to a target angle (default 0)
    %       turnClockwise           - Rotate clockwise by a given number of degrees
    %       turnCounterClockwise    - Rotate counterclockwise by a given number of degrees
    %       getStatus               - Query current status, position, and direction
    %       stop                    - Stop immediately any rotation in progress 
    %       close                   - Close the UDP connection
    %
    %   Example:
    %       t = Turntable('192.168.1.34');
    %       t.resetPosition(90);
    %       [status, position, direction] = t.getStatus();
    %       t.close();
    %
    %   Sergio de las Heras (sergio.delasheras@aalto.fi)
    %   2024

    properties
        u
        ipaddr 
        port
    end

    methods
        function obj = Turntable(ipaddr,port)
            % Turntable Construct an instance of this class
            %   obj = Turntable()                  - defaults to turntable #2
            %   obj = Turntable(1)                 - turntable #1 (130.233.150.101)
            %   obj = Turntable(2)                 - turntable #2 (192.168.1.34)
            %   obj = Turntable('192.168.1.99')    - explicit IP address
            %   obj = Turntable(ipaddr, port)      - explicit IP + port

            knownIPs = struct('tt1', '130.233.150.101', ...
                                'tt2', '192.168.1.34');
            
            if nargin < 1 || isempty(ipaddr)
                ipaddr = knownIPs.tt2; % Default to turntable 2
            elseif isnumeric(ipaddr)
                switch ipaddr
                    case 1
                        ipaddr = knownIPs.tt1;
                    case 2 
                        ipaddr = knownIPs.tt2;
                    otherwise
                        error('Turntable invalid turntable number', ...
                        'Unknown turntable number, use 1 or 2 or provide an IP')
                end
            elseif ischar(ipaddr) || isstring(ipaddr)
                ipaddr = char(ipaddr);
            end
            
            if nargin < 2 || isempty(port)
                port = 6668; 
            end

            obj.ipaddr = ipaddr;
            obj.port = port;
           
            try
                obj.u = udpport("byte");
            catch ME
                obj.u = 0;
                warning('Turntable:ConnectionFailed', ...
                    'Failed to create UDP port for %s:%d. %s', ...
                    ipaddr, port, ME.message);
            end

        end

        function reply = stop(obj)
            % STOP Immediately stop any turntable rotation

            % Format the message and deliver it (command code 3 = STOP, no argument)
            temp = sprintf('030000');
            cmd = [hex2dec(temp(1:2)) hex2dec(temp(3:4)) hex2dec(temp(5:6))];

            % Form the checksum
            checksum = uint8(bitxor(bitxor(uint8(cmd(1)),uint8(cmd(2))),uint8(cmd(3))));
            checksum = sprintf('%02x',checksum);

            cmd = [cmd hex2dec(checksum)];
            write(obj.u,cmd,"uint8",obj.ipaddr,obj.port);

            % Get reply
            status = read(obj.u,2,"uint8");

            status = sprintf('%02x%02x',status);

            if(strcmp(status,'3300'))
                reply = true;
            else
                reply = false;
            end

        end


        function resetPosition(obj, target)
    
            if nargin < 2
                target = 0;
            end    

            [~, position, ~] = obj.getStatus();
                delta = mod(target - position, 360);
            if delta <= 180
                reply = obj.turnClockwise(delta);
            else
                reply = obj.turnCounterClockwise(360 - delta);
            end

            % Error if was not possible
            if ~reply
                error('Turntable failed to reset position.');
            end


        end


        function reply = turnClockwise(obj, degrees)

        % Make sure that it is in 0.5 degree steps and multiply with 10 to correct
        % integer format.
        degrees = uint16(floor(degrees*2)*5);

        % A 0-degree move should be a no-op
        if degrees == 0
            reply = true;
            return;
        end

        % Format the message and deliver it
        temp = sprintf('01%04x',degrees);
        cmd = [hex2dec(temp(1:2)) hex2dec(temp(3:4)) hex2dec(temp(5:6))];

        % Form the checksum
        checksum = uint8(bitxor(bitxor(uint8(cmd(1)),uint8(cmd(2))),uint8(cmd(3))));
        checksum = sprintf('%02x',checksum);

        cmd = [cmd hex2dec(checksum)];
        write(obj.u,cmd,"uint8",obj.ipaddr,obj.port);

        % Get reply
        status = read(obj.u,2,"uint8");

        status = sprintf('%02x%02x',status);

        if(strcmp(status,'3300'))
            reply = true;
        else
            reply = false;
        end

        end


        function reply = turnCounterClockwise(obj,degrees)

        % Make sure that it is in 0.5 degree steps and multiply with 10 to correct
        % integer format.
        degrees = uint16(floor(degrees*2)*5);

        if degrees == 0
            reply = true;
            return;
        end

        % Format the message and deliver it
        temp = sprintf('02%04x',degrees);
        cmd = [hex2dec(temp(1:2)) hex2dec(temp(3:4)) hex2dec(temp(5:6))];

        % Form the checksum
        checksum = uint8(bitxor(bitxor(uint8(cmd(1)),uint8(cmd(2))),uint8(cmd(3))));
        checksum = sprintf('%02x',checksum);

        cmd = [cmd hex2dec(checksum)];
        write(obj.u,cmd,"uint8",obj.ipaddr,obj.port);

        % Get reply
        status = read(obj.u,2,"uint8");

        status = sprintf('%02x%02x',status);

        if(strcmp(status,'3300'))
            reply = 'true';
        else
            reply = 'false';
        end

        end


        function [status,position,direction] = getStatus(obj)

            % Format the message and deliver it
            temp = sprintf('040000');
            cmd = [hex2dec(temp(1:2)) hex2dec(temp(3:4)) hex2dec(temp(5:6))];
            
            % Form the checksum
            checksum = uint8(bitxor(bitxor(uint8(cmd(1)),uint8(cmd(2))),uint8(cmd(3))));
            checksum = sprintf('%02x',checksum);
            
            cmd = [cmd hex2dec(checksum)];
            write(obj.u,cmd,"uint8",obj.ipaddr,obj.port);
            
            % Get reply
            data = read(obj.u,7,"uint8");
            
            % Check that correct amount of data has been received. Otherwise flush
            % input buffer and bail out. Returns null in all outputs.
            if(length(data) < 7)
                flushinput(obj.u);
                status = 'null';
                direction = 'null';
                position = 0;
                return;
            end
            
            data = sprintf('%02x%02x%02x%02x%02x%02x%02x',data);
            
            if(strcmp(data(1:2),'05'))
                status = 'stopped';
            
                if(strcmp(data(11:12),'02'))
                    direction = 'clockwise';
                elseif(strcmp(data(11:12),'01'))
                    direction = 'counterclockwise';
                end
            
                position = hex2dec(data(3:10))/10;
            else
                status = 'moving';
                if(strcmp(data(11:12),'02'))
                    direction = 'clockwise';
                elseif(strcmp(data(11:12),'01'))
                    direction = 'counterclockwise';
                end
            
                position = hex2dec(data(3:10))/10;
            end

        end



        function close(obj)

            clear obj.u;

        end



    end
end