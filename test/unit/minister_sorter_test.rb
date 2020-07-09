require "test_helper"

class MinisterSorterTest < ActiveSupport::TestCase
  MockRole = Struct.new(:name, :seniority, :cabinet_member, :current_people) do
    def cabinet_member?
      cabinet_member
    end

    def inspect(*_args)
      "<role #{name}, seniority=#{seniority}, #{cabinet_member? ? 'cabinet' : 'other'}>"
    end
  end

  MockPerson = Struct.new(:sort_key) do
    def inspect(*_args)
      "<person #{sort_key}>"
    end
  end

  def role(*args)
    MockRole.new(*args)
  end

  def person(*args)
    MockPerson.new(*args)
  end

  def test_should_list_cabinet_ministers_by_person_sort_key
    a = person("a")
    b = person("b")
    c = person("c")
    d = person("d")

    role0 = role("r0", 0, true, [d])
    role1 = role("r1", 0, false, [c])
    role2 = role("r2", 0, true, [a, b])

    roles = [role0, role1, role2]

    expected = [
      [a, [role2]],
      [b, [role2]],
      [d, [role0]],
    ]

    set = MinisterSorter.new(roles)
    assert_equal expected, set.cabinet_ministers
  end

  def test_should_list_all_cabinet_ministers_roles_including_non_cabinet_roles_in_seniority_order
    roles = [
      role0 = role("r0", 2, false, [a = person("a")]),
      role1 = role("r1", 1, true, [a]),
      role2 = role("r2", 3, false, [a]),
    ]

    expected = [
      [a, [role1, role0, role2]],
    ]

    set = MinisterSorter.new(roles)
    assert_equal expected, set.cabinet_ministers
  end

  def test_should_list_ministers_with_no_cabinet_roles_by_person_sort_key
    a = person("a")
    b = person("b")
    c = person("c")

    role0 = role("r0", 0, false, [c, b])
    role1 = role("r1", 0, true, [c])
    role2 = role("r2", 0, false, [a])

    roles = [role0, role1, role2]

    expected = [
      [a, [role2]],
      [b, [role0]],
    ]

    set = MinisterSorter.new(roles)
    assert_equal expected, set.other_ministers
  end

  def test_should_list_cabinet_ministers_in_order_of_cabinet_role_seniority
    senior_person = person("0")
    junior_person = person("1")
    roles = [
      role("Senior Non Cabinet Role", 100, false, [senior_person]),
      role("Senior Cabinet Role", 16, true, [senior_person]),
      role("Junior Non Cabinet Role", 14, false, [junior_person]),
      role("Junior Cabinet Role", 17, true, [junior_person]),
    ]

    expected = [senior_person, junior_person]
    set = MinisterSorter.new(roles)

    assert_equal expected, set.cabinet_ministers.collect(&:first)
  end
end
