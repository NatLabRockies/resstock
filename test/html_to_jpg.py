from html2image import Html2Image
hti = Html2Image()

# screenshot an HTML file
hti.screenshot(
    html_file='test/base_results/comparisons/baseline/annual/results_output_energy_use.html',
    save_as='test/base_results/comparisons/baseline/annual/results_output_energy_use.jpg',
    # size=(1920, 1080)
    size=(3000, 1500)
)
