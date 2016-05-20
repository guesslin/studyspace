#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse


if __name__ == '__main__':
    """docstring placeholder
    """
    parser = argparse.ArgumentParser()

    """
    parser.add_argument('-o', '--output', type=argparse.FileType('wb', 0),
                        required=False)
    parser.add_argument('-i', '--infile', type=argparse.FileType('r'),
                        required=False)
    """
    parser.add_argument('-i', '--input', type=int, metavar='M')
    parser.add_argument(
        'square',
        help='echo the string you use here',
        type=int,
        metavar='N',
        nargs='?'
    )

    parser.add_argument('-v', '--verbosity', help='increase output verbosity',
                        action='store_true')

    args = parser.parse_args()
    if args.square:
        print args.square ** 2
    if args.input:
        print args.input ** 2

    """
    if args.verbosity:
        print 'verbosity is set'
    print args.output
    args.output.close()
    """
