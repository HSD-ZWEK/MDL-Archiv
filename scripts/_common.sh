#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

# Function to clone and install a Moodle plugin from a Git repository
install_plugin() {
    local DIR=$1
    local GIT_URL=$2
    local VERSION=$VERSION
    local GIT_BRANCHES=("MOODLE_${VERSION}_STABLE" "MOODLE_$((${VERSION} - 1))_STABLE" "MOODLE_$((${VERSION} - 2))_STABLE")

    echo "Attempting to install plugin in ${DIR} from ${GIT_URL}"

    # Check if the module is already installed
    if [ ! -d "${install_dir}/${DIR}" ]; then
        # Clone the module from the first available branch
        for BRANCH in "${GIT_BRANCHES[@]}"; do
            if git ls-remote "$GIT_URL" | grep -sw "$BRANCH" > /dev/null 2>&1; then
                echo "Cloning branch '$BRANCH'"
                git clone -b "$BRANCH" "$GIT_URL" "${install_dir}/${DIR}"
                break
            fi
        done

        # If no specific branch was cloned, clone the default branch
        if [ ! -d "${install_dir}/${DIR}" ]; then
            echo "No stable branch found. Cloning default branch."
            git clone "$GIT_URL" "${install_dir}/${DIR}"
        fi

        # Remove .git directory
        rm -rf "${install_dir}/${DIR}/.git"
    else
        echo "Plugin ${DIR} is already installed."
    fi
}

# Function to clone a Moodle theme from a Git repository
install_theme() {
    local DIR=$1
    local GIT_URL=$2
    local BRANCH=$3

    echo "Attempting to install theme in ${install_dir}/${DIR} from ${GIT_URL}"

    # Remove the existing theme directory if it exists
    if [ -d "${install_dir}/${DIR}" ]; then
        echo "Removing existing theme directory: ${install_dir}/${DIR}"
        rm -rf "${install_dir}/${DIR}"
    fi

    # Clone the theme if the specified branch exists in the repository
    if git ls-remote --heads "$GIT_URL" | grep -sw "refs/heads/$BRANCH" > /dev/null 2>&1; then
        echo "Cloning branch '$BRANCH' from $GIT_URL into ${install_dir}/${DIR}"
        git clone -b "$BRANCH" "$GIT_URL" "${install_dir}/${DIR}"
    else
        echo "Error: Branch '$BRANCH' does not exist in the repository."
        return 1
    fi
}

install_moosh() {
    # Check if moosh is already installed
    if command -v moosh > /dev/null 2>&1; then
        echo "moosh is already installed."
        return
    fi

    # Proceed with installation if moosh is not present
    git clone https://github.com/tmuras/moosh.git /opt/moosh
    rm -rf /opt/moosh/.git
    # Setting composer to allow superuser and update dependencies
    export COMPOSER_ALLOW_SUPERUSER=1; composer update --with-dependencies --working-dir=/opt/moosh
    # Installing composer dependencies
    export COMPOSER_ALLOW_SUPERUSER=1; composer install --working-dir=/opt/moosh
    # Creating a symbolic link for moosh
    ln -s /opt/moosh/moosh.php /usr/local/bin/moosh
}

#=================================================
# PERSONAL HELPERS
#=================================================

install_moodle_plugins() {

    # Extract branch from Moodle's version.php
    VERSION=$(grep 'branch' "${install_dir}/version.php" | tail -n 1 | cut -d"'" -f2)
    echo "Moodle branch extracted: $VERSION"

    # Display progress message
    ynh_script_progression --message="Installing plugins from git..." --weight=6

    # Admin tools
    install_plugin "admin/tool/inactive_user_cleanup" "https://github.com/dualcube/moodle-tool_inactive_user_cleanup"

    # Blocks
    moosh -n -p ${install_dir} plugin-install blocks_filtered_course_list

    # Local plugins
    moosh -n -p ${install_dir} plugin-install local_downloadcenter
    moosh -n -p ${install_dir} plugin-install local_cohortrole
    moosh -n -p ${install_dir} plugin-install local_navbarplus

    # Mod plugins
    moosh -n -p ${install_dir} plugin-install mod_board
    moosh -n -p ${install_dir} plugin-install mod_choicegroup
    install_plugin "mod/customcert" "https://github.com/mdjnelson/moodle-mod_customcert"
    install_plugin "mod/description" "https://github.com/emeneo/moodle-mod_description"
    install_plugin "mod/dialogue" "https://github.com/danmarsden/moodle-mod_dialogue"
    install_plugin "mod/etherpadlite" "https://github.com/moodlehu/moodle-mod_etherpadlite"
    install_plugin "mod/geogebra" "https://github.com/projectestac/moodle-mod_geogebra"
    install_plugin "mod/hotquestion" "https://github.com/drachels/moodle-mod_hotquestion"
    install_plugin "mod/hsuforum" "https://github.com/open-lms-open-source/moodle-mod_hsuforum"
    moosh -n -p ${install_dir} plugin-install mod_hvp
    install_plugin "mod/lightboxgallery" "https://github.com/open-lms-open-source/moodle-mod_lightboxgallery"
    install_plugin "mod/margic" "https://github.com/coactum/moodle-mod_margic"
    install_plugin "mod/mindmap" "https://github.com/t6nis/moodle-mod_mindmap"
    install_plugin "mod/moodleoverflow" "https://github.com/learnweb/moodle-mod_moodleoverflow"
    moosh -n -p ${install_dir} plugin-install mod_mumie
    install_plugin "mod/oublog" "https://github.com/moodleou/moodle-mod_oublog"
    install_plugin "mod/ouwiki" "https://github.com/moodleou/moodle-mod_ouwiki"
    install_plugin "mod/pcast" "https://github.com/sbourget/moodle-mod_pcast"
    moosh -n -p ${install_dir} plugin-install mod_poster
    install_plugin "mod/publication" "https://github.com/academic-moodle-cooperation/moodle-mod_publication"
    install_plugin "mod/questionnaire" "https://github.com/remotelearner/moodle-mod_questionnaire"
    install_plugin "mod/ratingallocate" "https://github.com/learnweb/moodle-mod_ratingallocate"
    moosh -n -p ${install_dir} plugin-install mod_scheduler
    install_plugin "mod/subpage" "https://github.com/moodleou/moodle-mod_subpage"
    install_plugin "mod/quiz/report/archive" "https://github.com/bfh/moodle-quiz_archive"

    # Microsoft plugins
    install_plugin "local/o365" "https://github.com/Microsoft/moodle-local_o365"
    install_plugin "auth/oidc" "https://github.com/Microsoft/moodle-auth_oidc"
    install_plugin "lib/editor/atto/plugins/teamsmeeting" "https://github.com/enovation/moodle-atto_teamsmeeting"
    install_plugin "repository/office365" "https://github.com/Microsoft/moodle-repository_office365"
    install_plugin "theme/boost_o365teams" "https://github.com/Microsoft/moodle-theme_boost_o365teams"
    install_plugin "blocks/microsoft" "https://github.com/Microsoft/moodle-block_microsoft"
    install_plugin "filter/oembed" "https://github.com/PoetOS/moodle-filter_oembed"
    install_plugin "local/office365" "https://github.com/Microsoft/moodle-local_office365"

    # Question types
    install_plugin "question/type/stack" "https://github.com/maths/moodle-qtype_stack"
    install_plugin "question/behaviour/adaptivemultipart" "https://github.com/maths/moodle-qbehaviour_adaptivemultipart"
    install_plugin "question/behaviour/dfcbmexplicitvaildate" "https://github.com/maths/moodle-qbehaviour_dfcbmexplicitvaildate"
    install_plugin "question/behaviour/dfexplicitvaildate" "https://github.com/maths/moodle-qbehaviour_dfexplicitvaildate"

    # Analytics
    install_plugin "admin/tool/log/store/lanalytics" "https://github.com/rwthanalytics/moodle-logstore_lanalytics.git"
    install_plugin "local/learning_analytics" "https://github.com/rwthanalytics/moodle-local_learning_analytics.git"

    # HSD Themes for Moodle 3
    install_theme "theme/hsd_blau" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/hsd_themes.git" "hsd_blau"
    install_theme "theme/hsd_blau2" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/hsd_themes.git" "hsd_blau2"
    install_theme "theme/hsd_gelb" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/hsd_themes.git" "hsd_gelb"
    install_theme "theme/hsd_gruen" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/hsd_themes.git" "hsd_gruen"
    install_theme "theme/hsd_rot" "git@gitlab.ruhr-uni-bochum.de:moodle-hsd/locally-hosted-submodules/hsd_themes.git" "hsd_rot"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
