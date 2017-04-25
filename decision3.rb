require 'csv.rb'

## GLOBALS

# List of dictionaries, each dictionary is one sample of data
$data = []
$test_set = []

# List of attribute names, in order given by CSV file
$attr_keys = [:school, :sex, :age, :address, :famsize, :Pstatus,:Medu, :Fedu, :caretaker, :Gcaretaker, :traveltime, :studytime, :failures, :schoolsup, :famsup, :paid, :activities, :nursery, :higher, :internet, :romantic, :famrel, :freetime, :goout, :Dalc, :Walc, :health, :absences, :result]
$final_attr = $attr_keys.last
$final_result = [0, 1]
$I_val = 0
$pos = 0
$neg = 0

## CLASSES
class Node
  attr_accessor :a, :threshold, :left, :right
  def initialize(a, threshold)
    @a = a
    @threshold = threshold
  end

  # In case we need to iterate over the tree
  def each(&block)
    left.each(&block) if left
    block.call(self)
    right.each(&block) if right
  end
end


## HELPERS
def same_class?(examples)
  if examples.empty?
    false
  end

  # Get the first classification
  classification = examples[0][$final_attr]

  # Check if the rest are the same
  examples.each do |ex|
    if ex[$final_attr] != classification
      return false
    end
  end

  # All of the examples had the same classification,
  # hence return true
  true
end

def MODE(examples)
  if examples.empty?
    NIL
  end

  # Count how many each classification has
  num_0 = count_result_examples($final_result[0], examples)
  num_1 = count_result_examples($final_result[1], examples)

  if num_0 > num_1
    $final_result[0]
  else
    $final_result[1]
  end
end

def get_examples(examples, direction, attr, threshold)
  # Return a list of examples that fall in the threshold

  new_examples = []

  if direction == 0
    # Going to the left
    examples.each do |ex|
      new_examples.push(ex) if ex[attr] <= threshold
    end
  else
    # Going to the right
    examples.each do |ex|
      new_examples.push(ex) if ex[attr] > threshold
    end
  end
  new_examples
end

# Counts the number of samples that have result as their final attribute value
def count_result_examples(result, examples)
  count = 0
  examples.each do |ex|
    #puts "ex[" + $final_attr.to_s + "]: " + ex[$final_attr].to_s + " result: " + result.to_s
    if ex[$final_attr].to_i == result.to_i
      count += 1
    end
  end
  count
end

def get_val_list(examples, attr)
  lst = []
  examples.each do |ex|
    lst.push(ex[attr])
  end
  lst.sort
end

def get_threshold_list(vals)
  thresholds = []
  vals[0..-2].each_with_index do |v1, index|
    v2 = vals[index+1]
    thresholds.push((v1+v2)/2.0)
  end
  thresholds
end

## MAIN/IMPORTANT FUNCTIONS

def log_2(num)
  if num == 0
    0
  else
    Math.log2(num)
  end
end

def Inf(ps, ng)

  #puts "ps: " + ps.to_s + " ng: " + ng.to_s
  p = ps.to_f / (ps + ng).to_f
  n = ng.to_f / (ps + ng).to_f

  #puts "p: " + p.to_s + " n: " + n.to_s
  -p*log_2(p) - n*log_2(n)
end

def remainder(attr, threshold, examples)
  # Get left information

  #puts "attr: " + attr.to_s + " threshold: " + threshold.to_s

  left_examples = get_examples(examples, 0, attr, threshold)
  #puts "left_examples " + left_examples.to_s

  n_l = count_result_examples($final_result[1], left_examples)
  p_l = count_result_examples($final_result[0], left_examples)

  #puts "n_1: " + n_l.to_s + " p_l: " + p_l.to_s

  # Get right information
  right_examples = get_examples(examples, 1, attr, threshold)

  #puts "right_examples " + right_examples.to_s

  n_r = count_result_examples($final_result[1], right_examples)
  p_r = count_result_examples($final_result[0], right_examples)

  #puts "n_r: " + n_r.to_s + " p_r: " + p_r.to_s

  if (n_l == 0 && p_l == 0)
    left_sum = 0.0
  else
    left_sum = (p_l + n_l).to_f/($pos + $neg) * Inf(p_l, n_l)
  end

  if (n_r == 0 && p_r == 0)
    right_sum = 0.0
  else
    right_sum = (p_r + n_r).to_f/($pos + $neg) * Inf(p_r, n_r)
  end

  left_sum + right_sum
end

def IG(examples, attr, threshold)
  # I((p/(p+n)), (n/(p+n))) - remainder(attr)

  #puts "IG val for: [" + attr.to_s + ", " + threshold.to_s + "] " + ($I_val - remainder(attr, threshold, examples)).to_s
  value = $I_val - remainder(attr, threshold, examples)

  if value.nan?
    puts "examples: " + examples.to_s
    exit(1)
  end

  value

end


def information_gain(examples, attr)
  # Finds the best information gain for a given attribute
  # by comparing the IG of different thresholds
  # Returns [best IG, threshold that gave best IG]

  # Create a list of attribute values over all of the examples given
  sorted_vals = get_val_list(examples, attr)

  # Create a list of thresholds from the average between two numbers
  # in the sorted_vals list
  thresholds = get_threshold_list(sorted_vals)

  best_threshold = thresholds[0]
  best_IG = IG(examples, attr, best_threshold)
  thresholds[1..-1].each do |t|
    curr_IG = IG(examples, attr, t)
    if curr_IG > best_IG
      best_threshold = t
      best_IG = curr_IG
    end
  end
  [best_IG, best_threshold]
end



def find_best_attribute(examples)
  # Return a Node class with Node.a = best attribute
  # and Node.threshold = threshold for best attribute

  # Best attribute is defined as the attribute with
  # the greatest information gain

  best = $attr_keys[0]
  best_IG_thres = information_gain(examples, best)

  #puts "starting best: " + best.to_s
  #puts "starting IG: " + best_IG_thres.to_s

  $attr_keys[1..-2].each do |attr|
    curr_IG_thres = information_gain(examples, attr)
    if curr_IG_thres[0] > best_IG_thres[0]
      best_IG_thres = curr_IG_thres
      best = attr
    end
  end

  Node.new(best, best_IG_thres[1])
end


def create_decision_tree(examples, default)

  if examples.empty?
    Node.new($final_attr, default)
  elsif same_class?(examples)
    Node.new($final_attr, examples[0][$final_attr])
  elsif $attr_keys.empty?
    # this should never happen since we do not remove attributes
    # however, just in case it does
    Node.new($final_attr, MODE(examples))
  else
    # Find the best attribute
    # Set current root to be [attribute, threshold]
    # For left value of best attribute
    # examples = examples <= threshold
    # current_root.left = create_decision_tree(examples, attributes, MODE(examples))
    # For the right value of best attribute
    # examples = examples > threshold
    # current_root.right = create_decision_tree(examples, attributes, MODE(examples))
    # Return current_root

    current_node = find_best_attribute(examples)
    left_examples = get_examples(examples, 0, current_node.a, current_node.threshold)
    right_examples = get_examples(examples, 1, current_node.a, current_node.threshold)
    #puts "size of left_examples: " + left_examples.count.to_s
    if right_examples.count == 0
      puts "left_examples 0!: " + right_examples.to_s + " empty? " + right_examples.empty?.to_s
    end
    #puts "size of right_examples: " + right_examples.count.to_s

    current_node.left = create_decision_tree(left_examples, MODE(left_examples))
    current_node.right = create_decision_tree(right_examples, MODE(right_examples))
    current_node
  end
end


def read_in_samples(filename, arr)

  CSV.foreach(filename) do |row|

    # Take each row and put into dictionary using attr_keys as the keys
    sample_dict = {}
    row.each_with_index do |attr_val, index|
      if index == $attr_keys.count - 1
        sample_dict[$attr_keys[index]] = attr_val
      else
        sample_dict[$attr_keys[index]] = attr_val.to_f
      end
    end

    # Place created dictionary into data array
    arr.push(sample_dict)

  end
end

def run_sample_on_tree(sample, node)
  if node.a == $final_attr
    node.threshold
  else
    if sample[node.a] <= node.threshold
      # Go left
      run_sample_on_tree(sample, node.left)
    else
      # Go right
      run_sample_on_tree(sample, node.right)
    end
  end
end

def print_tree(node, indent)

  for i in (0..indent-1)
    printf(" ")
  end

  printf("[Attribute: %s, Threshold: %f]\n", node.a, node.threshold)

  if node.left
    print_tree(node.left, indent+4)

  end

  if node.right
    print_tree(node.right, indent+4)
  end
end

## MAIN

# Read in data
read_in_samples('porto_math_train.csv', $data)

# Calculate I value
# Count how many each classification has
$pos = count_result_examples($final_result[0],$data)
$neg = count_result_examples($final_result[1], $data)

#puts $pos
#puts $neg

# Get the I value
$I_val = Inf($pos, $neg)

#puts "I_val" + $I_val.to_s

# Make decision tree
tree = create_decision_tree($data, MODE($data))

puts "----------------------------"
puts "Printing Tree..."
puts "----------------------------"
print_tree(tree, 0)
puts "----------------------------"

# Test on Training Set
num_correct = 0

$data.each_with_index do |sample, index|
  result = run_sample_on_tree(sample, tree)
  if result == sample[$final_attr]
    puts "Training Sample #" + index.to_s + " classification was CORRECT: " + result.to_s
    num_correct += 1
  else
    puts "Training Sample #" + index.to_s + " classification was NOT CORRECT: " + result.to_s
  end
end

printf("Percentage of Correct Classifications (Training): %f%%\n", (num_correct / $data.count.to_f) * 100)
puts "----------------------------"


# Test on Test Set
read_in_samples('porto_math_test.csv', $test_set)

num_correct = 0

$test_set.each_with_index do |sample, index|
  result = run_sample_on_tree(sample, tree)
  if result == sample[$final_attr]
    puts "Test Sample #" + index.to_s + " classification was CORRECT: " + result.to_s
    num_correct += 1
  else
    puts "Test Sample #" + index.to_s + " classification was NOT CORRECT: Result: " + result.to_s + " Actual: " + sample[$final_attr].to_s
  end
end

puts num_correct
printf("Percentage of Correct Classifications (Test): %f%%\n", (num_correct / $test_set.count.to_f) * 100)


