# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Role::ROLES.each do |role_name|
  Role.find_or_create_by(name: role_name)
end

Setting.create! unless Setting.first

if Organizer.all.empty?
  Organizer.create! name: "The Thomas Jefferson School", series_name: "TJS Conferences", abbreviation: "TJS"
  Organizer.create! name: "The Ayn Rand Institute (ARI)", series_name: "Objectivist Conferences", abbreviation: "OCON"
  Organizer.create! name: "Lyceum International", series_name: "Lyceum Conferences", abbreviation: "Lyceum"
  Organizer.create! name: "Lyceum International", series_name: "21st Century Conferences", abbreviation: "21CC"
  Organizer.create! name: "Conceptual Conferences", series_name: "Conceptual Conferences", abbreviation: "CC"
  Organizer.create! name: "Second Renaissance Conferences", series_name: "Second Renaissance Conferences", abbreviation: "SRC"
  Organizer.create! name: "Second Renaissance Books", series_name: "Second Renaissance Books Conferences", abbreviation: "SRB"
  Organizer.create! name: "The Hill Country Objectivist Association", series_name: "Texas Objectivist Conferences", abbreviation: "TOC"
  Organizer.create! name: "The Objective Standard", series_name: "The Objective Standard Conferences", abbreviation: "TOS-CON"
end
