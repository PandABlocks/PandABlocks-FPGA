    file = $fopen(filename, "r");
    if (file == `NULL) begin // If error opening file
        $display("Cannot find file %s", filename);
        $finish;
    end

    c = $fgetc(file);
    while (c != `EOF) begin
        /* Check the first character for comment */
        if (c == "T") begin
            r = $fgets(line, file);
            $display("%s\n", line);
        end
        else begin
            // Push the character back to the file then read the next time
            r = $ungetc(c, file);
            r = $fscanf(file,"%d\n", TS);

            wait (TS == timestamp) begin
                //$display("Timestamp = %d", TS);
                for (i = 1; i < N; i = i + 1) begin
                    r = $fscanf(file, "%d\n", vectors[i]);
                end
            end
        end
        c = $fgetc(file);
        @(posedge clk_i);
    end

    repeat(1250) @(posedge clk_i);
