#--
#Copyright 2007 Nominet UK
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#++

require_relative 'spec_helper'

class TestMessage < Minitest::Test

  include Dnsruby

  # Creates and returns sample message:
  #
  # ;; QUESTION SECTION (1  record)
  # ;; cnn.com.	IN	A
  # ;; Security Level : UNCHECKED
  # ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 7195
  # ;; flags: ; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 0
  def sample_message
    Message.new('cnn.com', 'A')
  end

  def test_question_section_formatted_ok
    multiline_regex = /QUESTION SECTION.+record.+cnn.com.\s+IN\s+A/m
    assert multiline_regex.match(sample_message.to_s)
  end

  def test_has_security_level_line
    line_regex = /^;; Security Level : .+/
    assert line_regex.match(sample_message.to_s)
  end

  def test_has_flags_and_section_count
    line_regex = /^;; flags:.+QUERY: \d+, ANSWER: \d+, AUTHORITY: \d+, ADDITIONAL: \d+/
    assert line_regex.match(sample_message.to_s)
  end

  def test_rd_flag_displayed_when_true
    message = sample_message
    message.header.instance_variable_set(:@rd, true)
    assert /;; flags(.+)rd/.match(message.to_s), message
  end

  def test_header_line_contains_opcode_and_status_and_id
    message = sample_message
    header_line = message.to_s.split("\n").grep(/->>HEADER<<-/).first
    line_regex = /->>HEADER<<- opcode: .+, status: .+, id: \d+/
    assert line_regex.match(header_line)
  end

  def test_getopt
    message = sample_message
    assert message.get_opt.nil?

    # Add an OPT record
    opt = RR::OPT.new(4096, 32768)
    message.additional << opt

    opt = message.get_opt
    assert opt.is_a?(Dnsruby::RR::OPT),
           "Expected get_opt to return a Dnsruby::RR::OPT, but it returned a #{opt.class}"
  end

  def test_2eq
    test = ->(msg1, msg2, expected_result) do
      assert (msg1 == msg2) == expected_result
    end
    msg_a = sample_message
    msg_b = sample_message; msg_b.header.rd = (! msg_b.header.rd)
    test.(msg_a, msg_a, true)
    test.(msg_a, msg_b, false)
    test.(msg_a, msg_a.to_s, false)
    test.(msg_a, nil, false)
    # TODO: Add more tests.
  end
end
