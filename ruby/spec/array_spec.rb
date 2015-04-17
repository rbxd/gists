require 'spec_helper'

describe Array do

  describe "#pattern_match" do
    it "should return true when pattern matching two empty arrays" do
      expect([] =~ []).to be true
    end

    it "should return true when pattern matching two equal arrays" do
      expect(["c"] =~ ["c"]).to be true
      expect([1,2] =~ [1,2]).to be true
      expect([:l,1,"c"] =~ [:l,1,"c"]).to be true
    end

    it "should return true when arrays are equal even unsorted" do
      expect([1,2] =~ [2,1]).to be true
      expect([:l,1,"c"] =~ [1,:l,"c"]).to be true
    end

    it "should return false when element types mismatch" do
      expect([true] =~ ['true']).to be false
      expect([1,:l] =~ [1,'l']).to be false
      expect([1,2] =~ [1,'2']).to be false
    end

    it "should return true when a2 is a subset of a1 (even unsorted)" do
      expect([1] =~ []).to be true
      expect([1,2] =~ [1]).to be true
      expect([:l,1,"c"] =~ ["c",:l]).to be true
    end

    it "should return false when a2 is not a subset nor equal to a1" do
      expect([1] =~ [1,2])
    end

    it "should recursively dive into nested arrays" do
      expect([[1,2,3],[3,4]] =~ [[1,2],[3,4]]).to be true
    end

    # TODO works for a class inheriting Array
  end
end
