# Brute force strategy of adding tags by checking line by line for our default tag and appending our tags after it
import argparse

# default tag added to know the cft was modified by this script
modified_tag_key = 'graffitied'
modified_tag_value = 'True'

# creates two arrays, one with propagation, one without
def initialize_tag_arrays(kv_pairs):
    tag_array = ['# Adding tags from customer' + '\n']
    tag_array_with_propagation = ['# Adding tags from customer with PropagateAtLaunch' + '\n']
    for k, v in kv_pairs:
        if k.lower() == 'name':
            print("Error: 'Name' is a reserved tag key. What were you thinking? Do you name your pets 'Dog'?")
            exit(1)
        tag_array.append('- Key: ' + k + '\n')
        tag_array.append('  Value: ' + v + '\n')
        tag_array_with_propagation.append('- Key: ' + k + '\n')
        tag_array_with_propagation.append('  Value: ' + v + '\n')
        tag_array_with_propagation.append('  PropagateAtLaunch: true' + '\n')
    return tag_array, tag_array_with_propagation


def parse_key_value_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    kv_pairs = []
    for line in lines:
        if ":" in line:
            kv_pairs.append(tuple(line.strip().split(': ')))
    kv_pairs.append((modified_tag_key, modified_tag_value))
    return kv_pairs


def append_tags(modified_lines, tag_array, leading_spaces):
    for tag in tag_array:
        modified_lines.append(' ' * leading_spaces + tag)


# Copy the original file and when we see "- Key: Product" we will append our tags
#  in the exact same way as the Product tag, including if we see PropagateAtLaunch
def create_modified_template(og_lines, tag_array, tag_array_with_propagation):
    modified_lines = []
    skip_lines = 0
    add_instance_tags = False
    add_propagate_tags = False
    for n, line in enumerate(og_lines):
        modified_lines.append(line)
        leading_spaces = len(line) - len(line.lstrip()) - 2
        if add_propagate_tags:
            add_propagate_tags = False
            append_tags(modified_lines, tag_array_with_propagation, leading_spaces)
        elif add_instance_tags:
            add_instance_tags = False
            modified_lines.append(' ' * (leading_spaces - 2) + '- ResourceType: instance\n')
            modified_lines.append(' ' * leading_spaces + 'Tags:\n')
            append_tags(modified_lines, tag_array, leading_spaces)
        if "Value: 'Pure:CBS'" in line:
            if "PropagateAtLaunch: " in og_lines[n + 1]:
                add_propagate_tags = True
            else:
                append_tags(modified_lines, tag_array, leading_spaces)

    return modified_lines


# Check if the starting template has already been tagged by this script using modified_tag_key
def validate_clean_starting_template(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    for line in lines:
        if modified_tag_key in line:
            print("Error: The starting template already been tagged by this script."
                  " Please start with a clean template.")
            exit(1)


def validate_args(args):
    if args.cft is None or args.cft[-5:] != '.yaml':
        print("Error: --cft argument is required and should be a yaml file")
        exit(1)
    if args.tags is None or args.tags[-5:] != '.yaml':
        print("Error: --tags argument is required and should be a yaml file")
        exit(1)


def add_parser_args():
    parser = argparse.ArgumentParser(description='Add tags to a cloudformation template')
    parser.add_argument('--cft', type=str, help='The path to the unedited cloudformation template')
    parser.add_argument('--tags', type=str, help='The path to the yaml key value file containing the tags to add')
    parser.add_argument('--output', type=str, help='The path to the new modified template')
    return parser.parse_args()


def main():
    args = add_parser_args()
    validate_args(args)
    validate_clean_starting_template(args.cft)
    kv_pairs = parse_key_value_file(args.tags)
    tag_array, tag_array_with_propagation = initialize_tag_arrays(kv_pairs)

    # Read the contents of the original file
    with open(args.cft, 'r') as file:
        lines = file.readlines()

    modified_lines = create_modified_template(lines, tag_array, tag_array_with_propagation)

    # Write the modified contents to a new file
    with open(args.output, 'w') as new_file:
        new_file.writelines(modified_lines)


if __name__ == '__main__':
    main()
