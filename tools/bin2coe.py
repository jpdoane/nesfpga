#!/usr/bin/python3

import argparse, os
import argparse
import numpy

def binary_to_coe(input_file, output_file, width):
    try:
        data = numpy.fromfile(input_file, dtype=numpy.uint32)
        # with open(input_file, 'rb') as f_in:
        with open(output_file, 'w') as f_out:
            f_out.write("memory_initialization_radix=16;\n")
            f_out.write("memory_initialization_vector=;\n")
            for word in data:
                hex_repr = "{:08x}".format(word)
                f_out.write(hex_repr)
            f_out.write(",\n")
            f_out.write(";")
    except FileNotFoundError:
        print("Error: Input file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert an arbitrary binary file to an ASCII text file.")
    parser.add_argument("input_file", help="Path to the input binary file")
    parser.add_argument("output_file", nargs='?', help="Path to the output ASCII text file (default: input file name with .mem extension)")
    parser.add_argument("width", nargs='?', help="bytes per entry (default: 4)")

    args = parser.parse_args()
    input_file_path = args.input_file
    output_file_path = args.output_file
    width = int(args.width)

    if not output_file_path:
        output_file_path = os.path.splitext(input_file_path)[0] + ".coe"
    if not width:
        width = 4

    binary_to_coe(input_file_path, output_file_path, width)
    print("Conversion complete.")