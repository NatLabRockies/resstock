from html2image import Html2Image
hti = Html2Image()

# screenshot an HTML file
hti.screenshot(
    html_file='results_output_energy_use.html',
    save_as='results_output_energy_use.jpg',
    # size=(1920, 1080)
    size=(3000, 1500)
)
