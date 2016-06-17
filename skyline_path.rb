require 'benchmark'
include Benchmark

require_relative 'ext/skyline_path_dsl'
require_relative 'structure/graph'

require_relative 'lib/dijkstra'

# for query skyline path
class SkylinePath < Graph
  include Dijkstra

  def initialize(params = {})
    super
    @skyline_path      = []
    @part_skyline_path = {}
  end

  def query_skyline_path(src_id: nil, dst_id: nil)
    query_check(src_id, dst_id)

    Benchmark.benchmark(CAPTION, 22, FORMAT, 'total:') do |step|
      t1 = step.report('Shorest path') do
        @skyline_path << shorest_path(src_id, dst_id)
      end
      t2 = step.report('SkyPath') do
        sky_path(src_id, dst_id)
      end
      [t1 + t2]
    end
    # "Found #{@skyline_path.size} Skyline paths"
    @skyline_path
  end

  private

  def minimal_paths
  end

  def sky_path(cur, dst, paths = [], pass = [])
    pass << cur
    if cur == dst
      paths, pass = arrived(cur, paths, pass)
      return
    end
    find_neighbors(cur).each do |n|
      sky_path(n, dst, paths, pass) if next_hop?(n, pass)
    end
    pass.delete(cur)
  end

  def arrived(cur, paths, pass)
    @skyline_path << pass.clone unless @skyline_path.include?(pass)
    [paths, pass.delete(cur)]
  end

  def next_hop?(n, pass)
    return false if pass.include?(n)
    next_path = pass + [n]
    partial_result = partial_dominance?(next_path)
    return false if partial_result
    add_part_skyline(next_path) unless partial_result.nil?
    return false if full_dominance?(next_path)
    true
  end

  def partial_dominance?(path)
    sym = "p#{path.first}_#{path.last}".to_sym
    result = false
    unless @part_skyline_path[sym].nil?
      result = @part_skyline_path[sym].dominate?(attrs_in(path))
    end
    result
  end

  def full_dominance?(path)
    @skyline_path.each do |sp|
      return true if attrs_in(sp).dominate?(attrs_in(path))
    end
    false # not be dominance
  end

  def add_part_skyline(path)
    path_attrs = attrs_in(path)
    sym = "p#{path.first}_#{path.last}".to_sym
    @part_skyline_path[sym] = path_attrs
  end

  def attrs_in(path)
    if path.size > 2
      edges_of_path = partition(path)
      attr_full = edges_of_path.inject(Array.new(@dim, 0)) do |attrs, edges|
        attrs.aggregate(attr_between(edges[0], edges[1]))
      end
    else
      attr_full = attr_between(path.first, path.last)
    end
    attr_full
  end

  def attr_between(src, dst)
    find_edge(src, dst).attrs
  end

  def query_check(src_id, dst_id)
    if src_id.nil? || dst_id.nil?
      raise ArgumentError, 'have to set src and dst both'
    end
    raise ArgumentError, 'src and dst have to different' if src_id == dst_id
    unless @nodes.include?(src_id)
      raise ArgumentError, 'src id needs to exist Node'
    end
    unless @nodes.include?(dst_id)
      raise ArgumentError, 'dst id needs to exist Node'
    end
  end
end

experiment = 'test'

case experiment
when 'test'
  EDGE_PATH = './test-data/test-edge.txt'.freeze
  NODE_PATH = './test-data/test-node.txt'.freeze
  DIM       = 4
end

test_edges = File.read(EDGE_PATH)
test_nodes = File.read(NODE_PATH)

sp = SkylinePath.new(dim: DIM, raw_edges: test_edges, raw_nodes: test_nodes)

p sp.query_skyline_path(src_id: 0, dst_id: 5)
