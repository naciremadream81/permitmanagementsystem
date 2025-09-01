-- Fix the major counties checklist items with correct IDs

-- Clear existing checklist items for major counties
DELETE FROM checklist_items WHERE county_id IN (6, 28, 43, 48, 50, 52);

-- Miami-Dade County (ID: 43)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(43, 'Building Permit Application', 'Complete and signed building permit application form', true, 1, NOW(), NOW()),
(43, 'Site Plan', 'Detailed site plan showing property boundaries, setbacks, and proposed construction', true, 2, NOW(), NOW()),
(43, 'Architectural Plans', 'Complete architectural drawings including floor plans, elevations, and sections', true, 3, NOW(), NOW()),
(43, 'Structural Plans', 'Structural engineering plans and calculations sealed by a Florida licensed engineer', true, 4, NOW(), NOW()),
(43, 'Electrical Plans', 'Electrical plans and load calculations', true, 5, NOW(), NOW()),
(43, 'Plumbing Plans', 'Plumbing plans and fixture schedules', true, 6, NOW(), NOW()),
(43, 'HVAC Plans', 'Mechanical plans for heating, ventilation, and air conditioning systems', true, 7, NOW(), NOW()),
(43, 'Energy Code Compliance', 'Energy efficiency compliance documentation (Florida Energy Code)', true, 8, NOW(), NOW()),
(43, 'Wind Load Calculations', 'Wind load analysis and hurricane impact compliance', true, 9, NOW(), NOW()),
(43, 'Flood Zone Compliance', 'Flood zone determination and elevation certificates if applicable', true, 10, NOW(), NOW()),
(43, 'Fire Department Review', 'Fire department plan review and approval', true, 11, NOW(), NOW()),
(43, 'Environmental Review', 'Environmental impact assessment if required', false, 12, NOW(), NOW()),
(43, 'Traffic Impact Study', 'Traffic impact analysis for large developments', false, 13, NOW(), NOW()),
(43, 'Landscape Plans', 'Landscaping and tree preservation plans', false, 14, NOW(), NOW()),
(43, 'Stormwater Management', 'Stormwater drainage and retention plans', true, 15, NOW(), NOW());

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

-- Orange County (ID: 48)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(48, 'Permit Application', 'Completed building permit application form', true, 1, NOW(), NOW()),
(48, 'Site Plan', 'Site plan showing existing and proposed improvements', true, 2, NOW(), NOW()),
(48, 'Building Plans', 'Architectural plans including floor plans and elevations', true, 3, NOW(), NOW()),
(48, 'Structural Plans', 'Structural engineering plans and calculations', true, 4, NOW(), NOW()),
(48, 'Electrical Plans', 'Electrical plans with load calculations and panel schedules', true, 5, NOW(), NOW()),
(48, 'Plumbing Plans', 'Plumbing plans with fixture schedules and water supply calculations', true, 6, NOW(), NOW()),
(48, 'Mechanical Plans', 'HVAC plans with equipment schedules and duct layouts', true, 7, NOW(), NOW()),
(48, 'Energy Code Compliance', 'Energy efficiency compliance forms and calculations', true, 8, NOW(), NOW()),
(48, 'Wind Mitigation', 'Wind mitigation features and hurricane tie-down details', true, 9, NOW(), NOW()),
(48, 'Zoning Verification', 'Zoning compliance letter or verification', true, 10, NOW(), NOW()),
(48, 'Tree Survey', 'Tree survey and preservation plan if required', false, 11, NOW(), NOW()),
(48, 'Traffic Study', 'Traffic impact study for developments over threshold', false, 12, NOW(), NOW());

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

-- Palm Beach County (ID: 50)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(50, 'Building Permit Application', 'Completed permit application with all required information', true, 1, NOW(), NOW()),
(50, 'Property Survey', 'Current survey showing property lines and existing structures', true, 2, NOW(), NOW()),
(50, 'Construction Plans', 'Complete set of construction documents', true, 3, NOW(), NOW()),
(50, 'Structural Plans', 'Structural engineering plans and calculations', true, 4, NOW(), NOW()),
(50, 'MEP Plans', 'Mechanical, electrical, and plumbing plans', true, 5, NOW(), NOW()),
(50, 'Hurricane Impact', 'Hurricane impact protection compliance', true, 6, NOW(), NOW()),
(50, 'Energy Compliance', 'Energy code compliance documentation', true, 7, NOW(), NOW()),
(50, 'Zoning Compliance', 'Zoning verification and development standards compliance', true, 8, NOW(), NOW()),
(50, 'Fire Safety', 'Fire department review and approval', true, 9, NOW(), NOW()),
(50, 'Environmental Permits', 'Environmental resource permits if applicable', false, 10, NOW(), NOW()),
(50, 'Traffic Analysis', 'Traffic impact analysis for qualifying developments', false, 11, NOW(), NOW()),
(50, 'Landscape Plan', 'Landscape and tree preservation plan', false, 12, NOW(), NOW());

-- Pinellas County (ID: 52)
INSERT INTO checklist_items (county_id, title, description, required, order_index, created_at, updated_at) VALUES
(52, 'Permit Application', 'Building permit application with property owner signature', true, 1, NOW(), NOW()),
(52, 'Site Plan', 'Site plan showing all improvements and setbacks', true, 2, NOW(), NOW()),
(52, 'Building Plans', 'Architectural plans including all required details', true, 3, NOW(), NOW()),
(52, 'Structural Plans', 'Structural engineering plans sealed by PE', true, 4, NOW(), NOW()),
(52, 'Electrical Plans', 'Electrical plans with service and load calculations', true, 5, NOW(), NOW()),
(52, 'Plumbing Plans', 'Plumbing plans with fixture schedules', true, 6, NOW(), NOW()),
(52, 'Mechanical Plans', 'HVAC plans with equipment schedules', true, 7, NOW(), NOW()),
(52, 'Energy Code', 'Energy efficiency compliance forms', true, 8, NOW(), NOW()),
(52, 'Wind Load Analysis', 'Wind load calculations and hurricane compliance', true, 9, NOW(), NOW()),
(52, 'Zoning Review', 'Zoning compliance verification', true, 10, NOW(), NOW()),
(52, 'Fire Review', 'Fire department plan review', true, 11, NOW(), NOW()),
(52, 'Environmental Review', 'Environmental impact review if required', false, 12, NOW(), NOW());

-- Verify the updated data
SELECT 
    c.name as county_name,
    COUNT(ci.id) as checklist_items
FROM counties c
LEFT JOIN checklist_items ci ON c.id = ci.county_id
WHERE c.id IN (6, 28, 43, 48, 50, 52)
GROUP BY c.id, c.name
ORDER BY c.name;
