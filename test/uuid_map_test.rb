require 'test_helper'
require_relative '../lib/uuid_map'

# As we need to sometimes move the file to a sibling directory, we need
# to make sure we create a tempfile one level deep in a subdir. There's
# possibly some option to Tempfile that does this in one shot, but I
# couldn't find it, so we instead create a dummy tempfile, then make a
# subdir at the same level as that, and put our "real" test file in it.
def new_tempfile
  Pathname.new(Tempfile.new(['data-ids', '.csv']).path)
end

describe 'UUID Mapper' do
  it "has nothing if the file doesn't exist" do
    UuidMapFile.new(Pathname.new('not/a/file')).mapping.must_be_empty
  end

  it 'has nothing in an empty tempfile' do
    UuidMapFile.new(new_tempfile).mapping.must_be_empty
  end

  it 'has new data after writing' do
    file = new_tempfile
    mapper = UuidMapFile.new(file)
    data = mapper.mapping
    data.must_be_empty
    data['fred'] = 'uuid-1'
    data['barney'] = 'uuid-2'
    mapper.rewrite(data)

    # read it back in again
    newmap = UuidMapFile.new(file)
    newmap.mapping.keys.count.must_equal 2
    newmap.uuid_for('barney').must_equal 'uuid-2'
    newmap.id_for('uuid-1').must_equal 'fred'
  end

  describe '#remap' do
    let(:file)   { new_tempfile }
    let(:mapper) { UuidMapFile.new(file) }
    let(:data)   { { 'fred' => 'uuid-1' } }

    it 'remaps existing UUID to a new id' do
      mapper.rewrite(data)
      mapper.remap('fred', 'freddy')
      mapper.uuid_for('fred').must_be_nil
      mapper.uuid_for('freddy').must_equal 'uuid-1'
    end

    it 'does not remap if old id does not exist' do
      mapper.rewrite(data)
      mapper.remap('frida', 'freddy')
      mapper.mapping.must_equal(data)
    end

    it 'does not remap if new id exists' do
      data['barney'] = 'uuid-2'
      mapper.rewrite(data)
      mapper.remap('fred', 'barney')
      mapper.mapping.must_equal(data)
    end
  end
end
