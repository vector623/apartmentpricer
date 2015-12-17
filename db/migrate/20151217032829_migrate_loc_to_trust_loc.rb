class MigrateLocToTrustLoc < ActiveRecord::Migration
  def up
    execute <<-SQL
      with x as
      (SELECT
        *,
        replace(location,'camden','') as newlocation,
        'camden' as newtrust
      FROM page_pulls
      where location like 'camden%')

      update page_pulls pp
      set location = newlocation, trust = newtrust
      from x
      where pp.id = x.id;

      with x as
      (SELECT
        *,
        replace(location,'camden','') as newlocation,
        'camden' as newtrust
      FROM floor_plans
      where location like 'camden%')

      update floor_plans pp
      set location = newlocation, trust = newtrust
      from x
      where pp.id = x.id;
    SQL
  end
  def down
    execute <<-SQL
      with x as
      (SELECT
        *,
        replace(trust::text || location::text,'camdencamden','camden') as newlocation
      FROM page_pulls
      where trust = 'camden')

      update page_pulls pp
      set location = newlocation
      from x
      where pp.id = x.id;

      with x as
      (SELECT
        *,
        replace(trust::text || location::text,'camdencamden','camden') as newlocation
      FROM floor_plans
      where trust = 'camden')

      update floor_plans pp
      set location = newlocation
      from x
      where pp.id = x.id;
    SQL
  end
end
