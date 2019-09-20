# jinja2 filters for use in templating


def clean_gcp_image_name(input: str):
    return input.replace("_", "-")
