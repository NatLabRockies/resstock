import os
import shutil
from html2image import Html2Image
hti = Html2Image()

html_file = 'test/base_results/comparisons/baseline/annual/results_output_energy_use.html'
save_as = 'results_output_energy_use.jpg'

# screenshot an HTML file
hti.screenshot(
    html_file=html_file,
    save_as=save_as,
    # size=(1920, 1080)
    size=(3000, 1500)
)

shutil.move(save_as, os.path.join(os.path.dirname(html_file), save_as))
