-- migrate:up
INSERT INTO categories (name, slug, icon, display_order) VALUES
    ('Ca nhạc',                'concert',           'music',           10),
    ('Lễ hội âm nhạc',         'music-festival',    'party-popper',    20),
    ('Sân khấu & Nghệ thuật',  'theater-arts',      'drama',           30),
    ('Hài kịch & Talkshow',    'comedy-talkshow',   'mic',             40),
    ('Thể thao',               'sports',            'trophy',          50),
    ('Hội thảo & Hội nghị',    'conference',        'presentation',    60),
    ('Workshop & Khóa học',    'workshop',          'lightbulb',       70),
    ('Triển lãm',              'exhibition',        'palette',         80),
    ('Ẩm thực',                'food-drink',        'utensils',        90),
    ('Gia đình & Trẻ em',      'family-kids',       'baby',           100),
    ('Du lịch & Trải nghiệm',  'travel-experience', 'map',            110),
    ('Networking',             'networking',        'users',          120),
    ('Khác',                   'other',             'more-horizontal', 999);

-- migrate:down

