# Restore exact original GAME-62 as temporary Git tag

This trigger requests verified staging of commit `0c15fcc77011d5dd1ca5418cbc67be1cee576360` without altering its tree or main. Publishing through a temporary tag allows subsequent GitHub App publication of the exact commit as a draft PR, while standard Actions token restrictions prevent creating branches directly with workflow additions. No merges.
