# Group-ICA on the Fetal Cortical Surface Using an Optimised Surface Projection Pipeline

🚀 **Presented at OHBM 2024**  
🧠 **Focus:** Fetal Brain Connectivity | Functional MRI | Surface-Based Analysis  

---

## 📝 Overview

This repository accompanies our work presented at the 2024 Organization for Human Brain Mapping (OHBM) conference, where we performed the **first-ever Group Independent Component Analysis (Group-ICA) on the fetal cortical surface**. Our analysis utilized an optimized surface projection pipeline, specifically designed to address the challenges posed by the dynamic morphology of the fetal brain during gestation.

Our approach facilitates a smooth transition across developmental stages by leveraging a spatio-temporal surface atlas. Several identified functional components revealed **distinctive interhemispheric symmetry**, suggesting the early emergence of bilateral cortical functional architecture.

---

## 🧬 Abstract

**Title:** *An Optimised Surface Projection Pipeline for Enhanced Analysis of Fetal Brain Connectivity*  
**Presented at:** OHBM 2024  
**Authors:** Pablo Prieto Roca, Logan Williams, Sean Fitzgibbon, Vanessa Kyriakopoulou, Alice Davidson, Alena Uus, Antonis Makropoulos, Andreas Schuh, Lucilio Cordero-Grande, Emer Hughes, Anthony Price, Eugene Duff, Tomoki Arichi, A. Edwards, Daniel Rueckert, Stephen Smith, Joseph Hajnal, Emma Robinson, Vyacheslav Karolis  

### Introduction

The fetal period is crucial for the emergence of the human functional connectome. However, analyzing this development is challenging due to the rapidly changing brain morphology. To overcome this, we propose a surface-based pipeline that projects volumetric fetal fMRI data onto spatio-temporal cortical surfaces, allowing robust group-level inference.

### Methods

We analyzed resting-state in-utero fMRI data from 164 healthy fetuses (24.5–38.5 weeks GA), using a modified version of the HCP surface mapping pipeline. Our novel framework employs multimodal surface matching (MSM) across a gestational surface atlas to enable smooth registration and group alignment.

We then performed a 25-component Group-ICA using FSL MELODIC on the mapped surface data.

### Results

This marks the **first surface-based Group-ICA** performed on the fetal brain. While some components were excluded as noise, several component pairs demonstrated **clear interhemispheric symmetry**, indicating early coordination across hemispheres during gestation.

### Conclusion

Our optimized pipeline enables reliable projection of fetal volumetric data onto surfaces, unlocking new possibilities for surface-based fetal brain studies. This method holds promise for advancing our understanding of in utero functional brain development.

---

## 🖼 Poster

📎 **[Download the Poster PDF](https://github.com/user-attachments/files/21615938/OHBM.Poster.PP.1.pdf)**

> 🧾 *Embedded preview may not display directly on GitHub. Please use the link above to view the full-resolution poster.*

---

## 📚 Citation

If you use this work or the pipeline in your own research, please cite our OHBM 2024 abstract.  
