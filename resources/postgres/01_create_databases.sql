-- stripo_plugin_local_bank_images
CREATE DATABASE stripo_plugin_local_bank_images;
CREATE USER user_bank_images WITH PASSWORD 'password_bank_images';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_bank_images TO user_bank_images;

-- stripo_plugin_local_custom_blocks
CREATE DATABASE stripo_plugin_local_custom_blocks;
CREATE USER user_custom_blocks WITH PASSWORD 'password_custom_blocks';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_custom_blocks TO user_custom_blocks;

-- stripo_plugin_local_documents
CREATE DATABASE stripo_plugin_local_documents;
CREATE USER user_documents WITH PASSWORD 'password_documents';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_documents TO user_documents;

-- stripo_plugin_local_drafts
CREATE DATABASE stripo_plugin_local_drafts;
CREATE USER user_drafts WITH PASSWORD 'password_drafts';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_drafts TO user_drafts;

-- stripo_plugin_local_html_gen
CREATE DATABASE stripo_plugin_local_html_gen;
CREATE USER user_html_gen WITH PASSWORD 'password_html_gen';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_html_gen TO user_html_gen;

-- stripo_plugin_local_plugin_details
CREATE DATABASE stripo_plugin_local_plugin_details;
CREATE USER user_plugin_details WITH PASSWORD 'password_plugin_details';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_plugin_details TO user_plugin_details;

-- stripo_plugin_local_plugin_stats
CREATE DATABASE stripo_plugin_local_plugin_stats;
CREATE USER user_plugin_stats WITH PASSWORD 'password_plugin_stats';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_plugin_stats TO user_plugin_stats;

-- stripo_plugin_local_securitydb
CREATE DATABASE stripo_plugin_local_securitydb;
CREATE USER user_securitydb WITH PASSWORD 'password_securitydb';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_securitydb TO user_securitydb;

-- stripo_plugin_local_timers
CREATE DATABASE stripo_plugin_local_timers;
CREATE USER user_timers WITH PASSWORD 'password_timers';
GRANT ALL PRIVILEGES ON DATABASE stripo_plugin_local_timers TO user_timers;

-- countdowntimer
CREATE DATABASE countdowntimer;
CREATE USER user_countdowntimer WITH PASSWORD 'password_countdowntimer';
GRANT ALL PRIVILEGES ON DATABASE countdowntimer TO user_countdowntimer;

-- ai_service
CREATE DATABASE ai_service;
CREATE USER user_ai_service WITH PASSWORD 'password_ai_service';
GRANT ALL PRIVILEGES ON DATABASE ai_service TO user_ai_service;
