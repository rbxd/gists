require 'spec_helper'

describe Hash do
  describe "#pattern_match" do
    it "should return true when pattern matching two empty hashes" do
      expect({} =~ {}).to be true
    end

    it "should return true when pattern matching two equal hashes" do
      expect({:k=>'v'} =~ {:k=>'v'}).to be true
      expect({:k=>'v', :x=>'y'} =~ {:k=>'v', :x=>'y'}).to be true
      expect({:k=>{}} =~ {:k=>{}}).to be true
    end

    it "should return true when hash2 is a subset of hash1" do
      expect({:k=>'v'} =~ {}).to be true
      expect({:k=>'v', :x=>'y'} =~ {:x=>'y'}).to be true
    end

    it "should return false when key types mismatch" do
      expect({:k=>'v'} =~ {'k'=>'v'}).to be false
    end

    it "should return false when value types mismatch" do
      expect({:k=>true} =~ {:k=>'true'}).to be false
    end

    it "should return false when hash2 is not a subset nor equal to hash1" do
      expect({} =~ {:k=>'v'}).to be false
      expect({:k=>'v'} =~ {:x=>'y'}).to be false
    end

    it "should recursively dive into nested hashes" do
      expect({:k=>{:k=>'v', :x=>'y'}, :z=>'w'} =~ {:k=>{:x=>'y'}}).to be true
      expect({:k=>{:k=>'v', :x=>'y'}, :z=>'w'} =~ {:k=>{:x=>'z'}}).to be false
    end

    it "should recursively dive into nested arrays" do
      expect( { :k => [{:k => 'v'}, {:x => 'v'}] } =~ { :k => [ {:x => 'v'}] }).to be true
      expect( { :k => [{:k => 'v'}, {:x => 'v'}] } =~ { :k => [ {:x => 'z'}] }).to be false
    end

    # TODO works for a class inheriting Hash
  end
end
