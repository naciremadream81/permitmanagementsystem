-- Florida Counties and Building Permit Checklists
-- Complete database seeding for all 67 Florida counties

-- Clear existing data
DELETE FROM permit_documents;
DELETE FROM permit_packages;
DELETE FROM checklist_items;
DELETE FROM counties;

-- Reset sequences
ALTER SEQUENCE counties_id_seq RESTART WITH 1;
ALTER SEQUENCE checklist_items_id_seq RESTART WITH 1;

-- Insert all 67 Florida counties
INSERT INTO counties (name, state, created_at, updated_at) VALUES
-- A
('Alachua County', 'FL', NOW(), NOW()),
-- B
('Baker County', 'FL', NOW(), NOW()),
('Bay County', 'FL', NOW(), NOW()),
('Bradford County', 'FL', NOW(), NOW()),
('Brevard County', 'FL', NOW(), NOW()),
('Broward County', 'FL', NOW(), NOW()),
-- C
('Calhoun County', 'FL', NOW(), NOW()),
('Charlotte County', 'FL', NOW(), NOW()),
('Citrus County', 'FL', NOW(), NOW()),
('Clay County', 'FL', NOW(), NOW()),
('Collier County', 'FL', NOW(), NOW()),
('Columbia County', 'FL', NOW(), NOW()),
-- D
('DeSoto County', 'FL', NOW(), NOW()),
('Dixie County', 'FL', NOW(), NOW()),
('Duval County', 'FL', NOW(), NOW()),
-- E
('Escambia County', 'FL', NOW(), NOW()),
-- F
('Flagler County', 'FL', NOW(), NOW()),
('Franklin County', 'FL', NOW(), NOW()),
-- G
('Gadsden County', 'FL', NOW(), NOW()),
('Gilchrist County', 'FL', NOW(), NOW()),
('Glades County', 'FL', NOW(), NOW()),
('Gulf County', 'FL', NOW(), NOW()),
-- H
('Hamilton County', 'FL', NOW(), NOW()),
('Hardee County', 'FL', NOW(), NOW()),
('Hendry County', 'FL', NOW(), NOW()),
('Hernando County', 'FL', NOW(), NOW()),
('Highlands County', 'FL', NOW(), NOW()),
('Hillsborough County', 'FL', NOW(), NOW()),
('Holmes County', 'FL', NOW(), NOW()),
-- I
('Indian River County', 'FL', NOW(), NOW()),
-- J
('Jackson County', 'FL', NOW(), NOW()),
('Jefferson County', 'FL', NOW(), NOW()),
-- L
('Lafayette County', 'FL', NOW(), NOW()),
('Lake County', 'FL', NOW(), NOW()),
('Lee County', 'FL', NOW(), NOW()),
('Leon County', 'FL', NOW(), NOW()),
('Levy County', 'FL', NOW(), NOW()),
('Liberty County', 'FL', NOW(), NOW()),
-- M
('Madison County', 'FL', NOW(), NOW()),
('Manatee County', 'FL', NOW(), NOW()),
('Marion County', 'FL', NOW(), NOW()),
('Martin County', 'FL', NOW(), NOW()),
('Miami-Dade County', 'FL', NOW(), NOW()),
('Monroe County', 'FL', NOW(), NOW()),
-- N
('Nassau County', 'FL', NOW(), NOW()),
-- O
('Okaloosa County', 'FL', NOW(), NOW()),
('Okeechobee County', 'FL', NOW(), NOW()),
('Orange County', 'FL', NOW(), NOW()),
('Osceola County', 'FL', NOW(), NOW()),
-- P
('Palm Beach County', 'FL', NOW(), NOW()),
('Pasco County', 'FL', NOW(), NOW()),
('Pinellas County', 'FL', NOW(), NOW()),
('Polk County', 'FL', NOW(), NOW()),
('Putnam County', 'FL', NOW(), NOW()),
-- S
('Santa Rosa County', 'FL', NOW(), NOW()),
('Sarasota County', 'FL', NOW(), NOW()),
('Seminole County', 'FL', NOW(), NOW()),
('St. Johns County', 'FL', NOW(), NOW()),
('St. Lucie County', 'FL', NOW(), NOW()),
('Sumter County', 'FL', NOW(), NOW()),
('Suwannee County', 'FL', NOW(), NOW()),
-- T
('Taylor County', 'FL', NOW(), NOW()),
-- U
('Union County', 'FL', NOW(), NOW()),
-- V
('Volusia County', 'FL', NOW(), NOW()),
-- W
('Wakulla County', 'FL', NOW(), NOW()),
('Walton County', 'FL', NOW(), NOW()),
('Washington County', 'FL', NOW(), NOW());

-- Standard Building Permit Checklist Items (will be applied to all counties with variations)

-- Major Counties (Miami-Dade, Broward, Orange, Hillsborough, Palm Beach, Pinellas) - More comprehensive requirements
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
-- Miami-Dade County (ID: 42)
(42, 'Building Permit Application', 'Complete and signed building permit application form', true, 1, NOW(), NOW()),
(42, 'Site Plan', 'Detailed site plan showing property boundaries, setbacks, and proposed construction', true, 2, NOW(), NOW()),
(42, 'Architectural Plans', 'Complete architectural drawings including floor plans, elevations, and sections', true, 3, NOW(), NOW()),
(42, 'Structural Plans', 'Structural engineering plans and calculations sealed by a Florida licensed engineer', true, 4, NOW(), NOW()),
(42, 'Electrical Plans', 'Electrical plans and load calculations', true, 5, NOW(), NOW()),
(42, 'Plumbing Plans', 'Plumbing plans and fixture schedules', true, 6, NOW(), NOW()),
(42, 'HVAC Plans', 'Mechanical plans for heating, ventilation, and air conditioning systems', true, 7, NOW(), NOW()),
(42, 'Energy Code Compliance', 'Energy efficiency compliance documentation (Florida Energy Code)', true, 8, NOW(), NOW()),
(42, 'Wind Load Calculations', 'Wind load analysis and hurricane impact compliance', true, 9, NOW(), NOW()),
(42, 'Flood Zone Compliance', 'Flood zone determination and elevation certificates if applicable', true, 10, NOW(), NOW()),
(42, 'Fire Department Review', 'Fire department plan review and approval', true, 11, NOW(), NOW()),
(42, 'Environmental Review', 'Environmental impact assessment if required', false, 12, NOW(), NOW()),
(42, 'Traffic Impact Study', 'Traffic impact analysis for large developments', false, 13, NOW(), NOW()),
(42, 'Landscape Plans', 'Landscaping and tree preservation plans', false, 14, NOW(), NOW()),
(42, 'Stormwater Management', 'Stormwater drainage and retention plans', true, 15, NOW(), NOW());

-- Broward County (ID: 6)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(6, 'Building Permit Application', 'Complete building permit application with all required signatures', true, 1, NOW(), NOW()),
(6, 'Property Survey', 'Current property survey showing boundaries and easements', true, 2, NOW(), NOW()),
(6, 'Construction Documents', 'Complete set of construction drawings and specifications', true, 3, NOW(), NOW()),
(6, 'Structural Engineering', 'Structural plans sealed by Florida licensed structural engineer', true, 4, NOW(), NOW()),
(6, 'MEP Plans', 'Mechanical, electrical, and plumbing plans', true, 5, NOW(), NOW()),
(6, 'Hurricane Protection', 'Hurricane impact protection plans and specifications', true, 6, NOW(), NOW()),
(6, 'Energy Compliance', 'Florida Energy Code compliance documentation', true, 7, NOW(), NOW()),
(6, 'Zoning Compliance', 'Zoning compliance verification and setback calculations', true, 8, NOW(), NOW()),
(6, 'Fire Safety Review', 'Fire department review for commercial projects', true, 9, NOW(), NOW()),
(6, 'Environmental Permits', 'Environmental permits if construction affects wetlands', false, 10, NOW(), NOW()),
(6, 'Accessibility Compliance', 'ADA compliance documentation for commercial buildings', true, 11, NOW(), NOW()),
(6, 'Soil Report', 'Geotechnical soil analysis for foundations', false, 12, NOW(), NOW());

-- Orange County (ID: 47)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(47, 'Permit Application', 'Completed building permit application form', true, 1, NOW(), NOW()),
(47, 'Site Plan', 'Site plan showing existing and proposed improvements', true, 2, NOW(), NOW()),
(47, 'Building Plans', 'Architectural plans including floor plans and elevations', true, 3, NOW(), NOW()),
(47, 'Structural Plans', 'Structural engineering plans and calculations', true, 4, NOW(), NOW()),
(47, 'Electrical Plans', 'Electrical plans with load calculations and panel schedules', true, 5, NOW(), NOW()),
(47, 'Plumbing Plans', 'Plumbing plans with fixture schedules and water supply calculations', true, 6, NOW(), NOW()),
(47, 'Mechanical Plans', 'HVAC plans with equipment schedules and duct layouts', true, 7, NOW(), NOW()),
(47, 'Energy Code Compliance', 'Energy efficiency compliance forms and calculations', true, 8, NOW(), NOW()),
(47, 'Wind Mitigation', 'Wind mitigation features and hurricane tie-down details', true, 9, NOW(), NOW()),
(47, 'Zoning Verification', 'Zoning compliance letter or verification', true, 10, NOW(), NOW()),
(47, 'Tree Survey', 'Tree survey and preservation plan if required', false, 11, NOW(), NOW()),
(47, 'Traffic Study', 'Traffic impact study for developments over threshold', false, 12, NOW(), NOW());

-- Hillsborough County (ID: 28)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(28, 'Building Permit Application', 'Complete application with property owner authorization', true, 1, NOW(), NOW()),
(28, 'Site Plan', 'Dimensioned site plan with setbacks and parking', true, 2, NOW(), NOW()),
(28, 'Architectural Drawings', 'Complete architectural plans and specifications', true, 3, NOW(), NOW()),
(28, 'Structural Engineering', 'Structural plans sealed by licensed professional engineer', true, 4, NOW(), NOW()),
(28, 'Electrical Plans', 'Electrical plans with service calculations', true, 5, NOW(), NOW()),
(28, 'Plumbing Plans', 'Plumbing plans with fixture units and sizing', true, 6, NOW(), NOW()),
(28, 'Mechanical Plans', 'HVAC plans with equipment specifications', true, 7, NOW(), NOW()),
(28, 'Energy Code Compliance', 'Florida Energy Code compliance documentation', true, 8, NOW(), NOW()),
(28, 'Hurricane Compliance', 'Hurricane protection and wind load compliance', true, 9, NOW(), NOW()),
(28, 'Fire Department Review', 'Fire department plan review and comments', true, 10, NOW(), NOW()),
(28, 'Environmental Review', 'Environmental screening and permits if needed', false, 11, NOW(), NOW()),
(28, 'Concurrency Review', 'Transportation concurrency review for large projects', false, 12, NOW(), NOW());

-- Palm Beach County (ID: 49)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(49, 'Building Permit Application', 'Completed permit application with all required information', true, 1, NOW(), NOW()),
(49, 'Property Survey', 'Current survey showing property lines and existing structures', true, 2, NOW(), NOW()),
(49, 'Construction Plans', 'Complete set of construction documents', true, 3, NOW(), NOW()),
(49, 'Structural Plans', 'Structural engineering plans and calculations', true, 4, NOW(), NOW()),
(49, 'MEP Plans', 'Mechanical, electrical, and plumbing plans', true, 5, NOW(), NOW()),
(49, 'Hurricane Impact', 'Hurricane impact protection compliance', true, 6, NOW(), NOW()),
(49, 'Energy Compliance', 'Energy code compliance documentation', true, 7, NOW(), NOW()),
(49, 'Zoning Compliance', 'Zoning verification and development standards compliance', true, 8, NOW(), NOW()),
(49, 'Fire Safety', 'Fire department review and approval', true, 9, NOW(), NOW()),
(49, 'Environmental Permits', 'Environmental resource permits if applicable', false, 10, NOW(), NOW()),
(49, 'Traffic Analysis', 'Traffic impact analysis for qualifying developments', false, 11, NOW(), NOW()),
(49, 'Landscape Plan', 'Landscape and tree preservation plan', false, 12, NOW(), NOW());

-- Pinellas County (ID: 51)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(51, 'Permit Application', 'Building permit application with property owner signature', true, 1, NOW(), NOW()),
(51, 'Site Plan', 'Site plan showing all improvements and setbacks', true, 2, NOW(), NOW()),
(51, 'Building Plans', 'Architectural plans including all required details', true, 3, NOW(), NOW()),
(51, 'Structural Plans', 'Structural engineering plans sealed by PE', true, 4, NOW(), NOW()),
(51, 'Electrical Plans', 'Electrical plans with service and load calculations', true, 5, NOW(), NOW()),
(51, 'Plumbing Plans', 'Plumbing plans with fixture schedules', true, 6, NOW(), NOW()),
(51, 'Mechanical Plans', 'HVAC plans with equipment schedules', true, 7, NOW(), NOW()),
(51, 'Energy Code', 'Energy efficiency compliance forms', true, 8, NOW(), NOW()),
(51, 'Wind Load Analysis', 'Wind load calculations and hurricane compliance', true, 9, NOW(), NOW()),
(51, 'Zoning Review', 'Zoning compliance verification', true, 10, NOW(), NOW()),
(51, 'Fire Review', 'Fire department plan review', true, 11, NOW(), NOW()),
(51, 'Environmental Review', 'Environmental impact review if required', false, 12, NOW(), NOW());

-- Standard checklist for medium-sized counties (simplified but comprehensive)
-- This will be applied to counties like Duval, Lee, Polk, Volusia, etc.

-- Function to create standard medium county checklist
DO $$
DECLARE
    county_ids INTEGER[] := ARRAY[15, 35, 52, 59, 34, 40, 54, 17, 45, 53, 41, 44, 26, 30, 36, 10, 8, 50];
    county_id INTEGER;
BEGIN
    FOREACH county_id IN ARRAY county_ids
    LOOP
        INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
        (county_id, 'Building Permit Application', 'Complete building permit application form', true, 1, NOW(), NOW()),
        (county_id, 'Site Plan', 'Site plan showing property boundaries and proposed construction', true, 2, NOW(), NOW()),
        (county_id, 'Building Plans', 'Architectural plans including floor plans and elevations', true, 3, NOW(), NOW()),
        (county_id, 'Structural Plans', 'Structural engineering plans if required', true, 4, NOW(), NOW()),
        (county_id, 'Electrical Plans', 'Electrical plans and load calculations', true, 5, NOW(), NOW()),
        (county_id, 'Plumbing Plans', 'Plumbing plans and fixture schedules', true, 6, NOW(), NOW()),
        (county_id, 'Mechanical Plans', 'HVAC plans and equipment specifications', true, 7, NOW(), NOW()),
        (county_id, 'Energy Code Compliance', 'Florida Energy Code compliance documentation', true, 8, NOW(), NOW()),
        (county_id, 'Wind Load Compliance', 'Wind load calculations and hurricane compliance', true, 9, NOW(), NOW()),
        (county_id, 'Zoning Compliance', 'Zoning verification and setback compliance', true, 10, NOW(), NOW()),
        (county_id, 'Environmental Review', 'Environmental permits if construction affects sensitive areas', false, 11, NOW(), NOW());
    END LOOP;
END $$;

-- Basic checklist for smaller/rural counties
-- This will be applied to remaining counties with simpler requirements

DO $$
DECLARE
    county_ids INTEGER[] := ARRAY[1, 2, 3, 4, 7, 9, 11, 12, 13, 14, 16, 18, 19, 20, 21, 22, 23, 24, 25, 27, 29, 31, 32, 33, 37, 38, 39, 43, 46, 48, 55, 56, 57, 58, 60, 61, 62, 63, 64, 65, 66, 67];
    county_id INTEGER;
BEGIN
    FOREACH county_id IN ARRAY county_ids
    LOOP
        INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
        (county_id, 'Building Permit Application', 'Completed building permit application', true, 1, NOW(), NOW()),
        (county_id, 'Site Plan', 'Simple site plan showing building location and setbacks', true, 2, NOW(), NOW()),
        (county_id, 'Building Plans', 'Basic building plans and elevations', true, 3, NOW(), NOW()),
        (county_id, 'Electrical Plans', 'Electrical plans for new construction', true, 4, NOW(), NOW()),
        (county_id, 'Plumbing Plans', 'Plumbing plans if applicable', true, 5, NOW(), NOW()),
        (county_id, 'Energy Compliance', 'Basic energy code compliance', true, 6, NOW(), NOW()),
        (county_id, 'Zoning Verification', 'Zoning compliance verification', true, 7, NOW(), NOW()),
        (county_id, 'Septic System Permit', 'Septic system permit if not connected to sewer', false, 8, NOW(), NOW()),
        (county_id, 'Well Permit', 'Water well permit if not connected to public water', false, 9, NOW(), NOW());
    END LOOP;
END $$;

-- Verify the data
SELECT 
    c.name as county_name,
    COUNT(ci.id) as checklist_items
FROM counties c
LEFT JOIN checklist_items ci ON c.id = ci.county_id
GROUP BY c.id, c.name
ORDER BY c.name;
